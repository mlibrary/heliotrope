# frozen_string_literal: true

# 3.3.9 Zero Usage
# Not all content providers or other COUNTER report providers link their COUNTER reporting tool to their subscription database,
# so R5 reports cannot include zero-usage reporting based on subscription records. Inclusion of zero-usage reporting for everything,
# including unsubscribed content, could make reports unmanageably large. The need for libraries to identify subscribed titles
# with zero usage will be addressed by the KBART Automation Working Group initiative.
#
# For tabular reports
#
# Omit any row where the Reporting_Period_Total would be zero.
# If the Reporting_Period_Total is not zero, but usage for an included month is zero, set the cell value for that month to 0.
#
# For JSON reports
#
# Omit any Instance element with a Count of zero.
# Omit Performance elements that don’t have at least one Instance element.
# Omit Report_Items elements that don’t have at least one Performance element.

module CounterReporter
  class ItemReport # rubocop:disable Metrics/ClassLength
    attr_reader :params, :all_ebooks

    def initialize(params)
      @params = params
      @all_ebooks = FeaturedRepresentative.where(kind: ['epub', 'pdf_ebook']).map(&:file_set_id)
    end

    def report # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      metric_types = @params.metric_types
      data_types = @params.data_types
      access_types = @params.access_types
      access_methods = @params.access_methods

      if @params.counter_5_report
        metric_types = @params.allowed_metric_types if metric_types.blank?
        data_types = @params.allowed_data_types if data_types.blank?
        access_types = @params.allowed_access_types if access_types.blank?
        access_methods = @params.allowed_access_methods if access_methods.blank?
      end

      data_type = data_types.first
      access_method = access_methods.first

      yop_range = @params.yop_values
      yop_range[1] = yop_range[0] if yop_range.present? && yop_range[1] == nil

      results = results_by_month(metric_types, access_types)
      items = []

      file_sets = presenters_for(Hyrax::FileSetPresenter, unique_noids(results, metric_types, access_types))
      parents = presenters_for(Hyrax::MonographPresenter, unique_parent_noids(results, metric_types, access_types))

      unique_results(results, metric_types, access_types).sort_by { |k, _v| parents[k[0]].present? ? parents[k[0]]&.page_title : "" }.each do |key, _reporting_period_total|  # rubocop:disable Metrics/BlockLength
        parent_noid = key[0]
        noid        = key[1]
        section     = key[2]
        comp_title  = key[3]
        parent      = parents[parent_noid]
        presenter   = file_sets[noid]

        next if parent.nil?
        next if presenter.nil? # deleted file_sets or something...
        next if @params.report_type == 'ir_m1' && !presenter.multimedia?
        yop = find_yop(parent)
        next if yop_range.present? && (yop < yop_range[0] || yop > yop_range[1])

        metric_types.each do |metric_type|
          access_types.each do |access_type|
            item = new_item(results, parent, presenter, section, comp_title, metric_type, access_method, access_type, data_type)
            next if @params.counter_5_report && item["Reporting_Period_Total"] == 0

            items << item
          end
        end
      end

      items = [[]] if items.empty?

      { header: header(metric_types), items: items }
    end

    def new_item(results, parent, child, section, comp_title, metric_type, access_method, access_type, data_type)  # rubocop:disable Metrics/ParameterLists
      item = ActiveSupport::OrderedHash.new
      item["Item"] = child.page_title
      item["Publisher"] = child.publisher.first || parent.publisher.first
      item["Publisher_ID"] = ""
      item["Platform"] = "Fulcrum/#{@params.press.name}"
      item["Authors"] = find_authors(child, parent) if @params.attributes_to_show.include?("Authors")
      item["Publication_Date"] = child.date_created.first || parent.date_created.first if @params.attributes_to_show.include?("Publication_Date")
      item["Article_Version"] = "" if @params.attributes_to_show.include?("Article_Version")
      item["DOI"] = child.citable_link
      item["Proprietary_ID"] = child.id
      unless @params.report_type == 'ir_m1'
        item["ISBN"] = parent.isbn.join(", ")
        item["Print_ISSN"] = ""
        item["Online_ISSN"] = ""
      end
      item["URI"] = find_url(child, section)
      if @params.include_parent_details
        item["Parent_Title"] = parent.page_title
        item["Parent_Authors"] = ""
        item["Parent_Publication_Date"] = ""
        item["Parent_Article_Version"] = ""
        item["Parent_Data_Type"] = "Book"
        item["Parent_DOI"] = parent.citable_link
        item["Parent_Proprietary_ID"] = parent.id
        item["Parent_ISBN"] = ""
        item["Parent_Print_ISSN"] = ""
        item["Parent_Online_ISSN"] = ""
        item["Parent_URI"] = Rails.application.routes.url_helpers.hyrax_monograph_url(parent.id)
      end
      if @params.include_component_details
        item["Component_Title"] = comp_title
        item["Component_Authors"] = ""
        item["Component_Publication_Date"] = ""
        item["Component_Data_Type"] = ""
        item["Component_DOI"] = ""
        item["Component_Proprietary_ID"] = ""
        item["Component_ISBN"] = ""
        item["Component_Print_ISSN"] = ""
        item["Component_Online_ISSN"] = ""
        item["Component_URI"] = ""
      end
      item["Data_Type"] = find_data_type(child, section) if @params.attributes_to_show.include?("Data_Type")
      item["YOP"] = find_yop(parent) if @params.attributes_to_show.include?("YOP")
      item["Access_Type"] = access_type if @params.attributes_to_show.include?("Access_Type")
      item["Access_Method"] = access_method if @params.attributes_to_show.include?("Access_Method")
      item["Metric_Type"] = metric_type
      item["Reporting_Period_Total"] = results.values.filter_map { |r| r[metric_type.downcase][access_type.downcase][[parent.id, child.id, section, comp_title]] }.sum
      if @params.include_monthly_details
        results.each do |month, result|
          item[month] = result[metric_type.downcase][access_type.downcase][[parent.id, child.id, section, comp_title]] || 0
        end
      end
      item
    end

    def header(metric_types)
      institution_ids = []
      institution_name = if @params.institution == '*'
                           institution_ids << '*'
                           "All Institutions"
                         else
                           institution = Greensub::Institution.find_by(identifier: @params.institution)
                           institution_ids << 'ID:' + institution.identifier.to_s
                           institution_ids << 'ROR:' + institution.ror_id.to_s if institution.ror_id.present?
                           institution.name
                         end
      report_filters = []
      report_filters << "Platform=#{@params.platforms.join('|')}"
      report_filters << "Data_Type=#{@params.data_types.join('|')}" if @params.data_types.present?
      report_filters << "YOP=#{@params.yop}" if @params.yop.present?
      report_filters << "Access_Type=#{@params.access_types.join('|')}" if @params.access_types.present?
      report_filters << "Access_Method=#{@params.access_methods.join('|')}" if @params.access_methods.present?
      report_attributes = []
      report_attributes << "Attributes_To_Show=#{@params.attributes_to_show.join('|')}" if @params.attributes_to_show.present?
      report_attributes << "Include_Parent_Details=True" if @params.include_parent_details.present?
      report_attributes << "Include_Component_Details=True" if @params.include_component_details.present?
      report_attributes << "Exclude_Monthly_Details=True" if @params.include_monthly_details.blank?
      # Date range requested for the report in the form of “Begin_Date=yyyy-mm-dd; End_Date=yyyy-mm-dd”.
      # The “dd” of the Begin_Date is 01. The “dd” of the End_Date is the last day of the month.
      # start_date = "%4d-%02d-%02d" % [@params.start_date.year, @params.start_date.month, 1]
      start_date = @params.start_date.beginning_of_month.strftime("%Y-%m-%d")
      end_date = @params.end_date.end_of_month.strftime("%Y-%m-%d")
      {
        Report_Name: @params.report_title,
        Report_ID: @params.report_type.upcase,
        Release: "5",
        Institution_Name: institution_name,
        Institution_ID: institution_ids.join("; "),
        Metric_Types: metric_types.join("; "),
        Report_Filters: report_filters.join("; "),
        Report_Attributes: report_attributes.join("; "),
        Exceptions: "",
        Reporting_Period: "Begin_Date=#{start_date}; End_Date=#{end_date}",
        Created: Time.zone.today.iso8601,
        Created_By: "Fulcrum/#{@params.press.name}"
      }
    end

    def find_yop(title)
      # should "yop"/year of publication be in the counter_report table?
      title.date_created.first || "0001"
    end

    def find_data_type(presenter, section)
      # Possible "Data_Types" include: "multimedia", "book", "book segement", etc
      # See 3.3.2 Data Types at https://www.projectcounter.org/code-of-practice-five-sections/3-0-technical-specifications/
      return "Book_Segment" if section == "Chapter"
      return "Multimedia" if presenter.multimedia?
      return "Book" if @all_ebooks.include? presenter.id
      "Other"
    end

    def find_authors(presenter, parent)
      # A lot fo file_set authors have email addresses (of staff), which we don't want
      creator = presenter.creator.first
      return parent.authors if creator.nil?
      return parent.authors if creator.match? '@'
      creator
    end

    def find_url(presenter, section)
      return Rails.application.routes.url_helpers.epub_url(presenter.id) if section == "Chapter"
      return Rails.application.routes.url_helpers.epub_url(presenter.id) if @all_ebooks.include? presenter.id
      Rails.application.routes.url_helpers.hyrax_file_set_url(presenter.id)
    end

    def unique_results(results, metric_types, access_types)
      ur = {}
      results.values.each do |result|
        metric_types.each do |metric_type|
          access_types.each do |access_type|
            result[metric_type.downcase][access_type.downcase].each do |k, v|
              ur[k] = if ur[k].present?
                        ur[k] + v.to_i
                      else
                        v.to_i
                      end
            end
          end
        end
      end
      ur
    end

    def unique_noids(results, metric_types, access_types)
      noids = []
      results.values.each do |result|
        metric_types.each do |metric_type|
          access_types.each do |access_type|
            noids.concat(result[metric_type.downcase][access_type.downcase].keys.map { |r| r[1] })
          end
        end
      end
      noids.uniq
    end

    def unique_parent_noids(results, metric_types, access_types)
      parent_noids = []
      results.values.each do |result|
        metric_types.each do |metric_type|
          access_types.each do |access_type|
            parent_noids.concat(result[metric_type.downcase][access_type.downcase].keys.map { |r| r[0] })
          end
        end
      end
      parent_noids.uniq
    end

    def presenters_for(hyrax_presenter, noids)
      presenters = {}
      until noids.empty?
        Hyrax::PresenterFactory.build_for(ids: noids.shift(999), presenter_class: hyrax_presenter, presenter_args: nil).map do |p|
          presenters[p.id] = p
        end
      end
      presenters
    end

    def results_by_month(metric_types, access_types)
      results = ActiveSupport::OrderedHash.new
      this_month = @params.start_date
      until this_month > @params.end_date
        item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
        results[item_month] = {}
        metric_types.each do |metric_type|
          results[item_month][metric_type.downcase] = {}
          access_types.each do |access_type|
            results[item_month][metric_type.downcase][access_type.downcase] = send(metric_type.downcase, this_month, access_type)
          end
        end
        this_month = this_month.next_month
      end
      results
    end

    def total_item_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press)
                   .where(model: "FileSet")
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end

    def unique_item_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press)
                   .where(model: "FileSet")
                   .unique
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end

    def unique_title_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press)
                   .where(model: "FileSet")
                   .unique_by_title
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end

    def total_item_requests(month, access_type)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press)
                   .where(model: "FileSet")
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end

    def unique_item_requests(month, access_type)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press)
                   .where(model: "FileSet")
                   .unique
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end

    def unique_title_requests(month, access_type)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press)
                   .where(model: "FileSet")
                   .unique_by_title
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end

    def limit_exceeded(month, _access_type)
      # raise "The Limit_Exceeded turnaway metric is not currently tracked/implemented"
      CounterReport.institution(@params.institution)
                   .turnaway("Limit_exceeded")
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end

    def no_license(month, _access_type)
      CounterReport.institution(@params.institution)
                   .turnaway("No_License")
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .group('parent_noid', 'noid', 'section_type', 'section')
                   .count
    end
  end
end
