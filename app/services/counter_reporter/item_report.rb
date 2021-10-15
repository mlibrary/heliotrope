# frozen_string_literal: true

module CounterReporter
  class ItemReport
    attr_reader :params, :all_ebooks

    def initialize(params)
      @params = params
      @all_ebooks = FeaturedRepresentative.where(kind: ['epub', 'pdf_ebook']).map(&:file_set_id)
    end

    def report # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      results = results_by_month
      items = []

      file_sets = presenters_for(Hyrax::FileSetPresenter, unique_noids(results))
      parents = presenters_for(Hyrax::MonographPresenter, unique_parent_noids(results))

      unique_results(results).sort_by { |k, _v| parents[k[0]].present? ? parents[k[0]]&.page_title : "" }.each do |key, _reporting_period_total|  # rubocop:disable Metrics/BlockLength
        parent_noid = key[0]
        noid        = key[1]
        section     = key[2]
        comp_title  = key[3]
        parent      = parents[parent_noid]
        presenter   = file_sets[noid]

        next if parent.nil?
        next if presenter.nil? # deleted file_sets or something...
        next if @params.report_type == 'ir_m1' && !presenter.multimedia?
        next if @params.yop.present? && @params.yop != parent.date_created.first

        @params.metric_types.each do |metric_type| # rubocop:disable Metrics/BlockLength
          @params.access_types.each do |access_type| # rubocop:disable Metrics/BlockLength
            item = ActiveSupport::OrderedHash.new
            item["Item"] = presenter.page_title
            item["Publisher"] = presenter.publisher.first || parent.publisher.first
            item["Publisher_ID"] = ""
            item["Platform"] = "Fulcrum/#{@params.press.name}"
            item["Authors"] = find_authors(presenter, parent)
            item["Publication_Date"] = presenter.date_created.first || parent.date_created.first
            item["Article_Version"] = ""
            item["DOI"] = presenter.citable_link
            item["Proprietary_ID"] = presenter.id
            item["ISBN"] = parent.isbn.join(", ")
            item["Print_ISSN"] = ""
            item["Online_ISSN"] = ""
            item["URI"] = find_url(presenter, section)
            item["Parent_Title"] = parent.page_title
            item["Parent_Data_Type"] = "Book"
            item["Parent_DOI"] = parent.citable_link
            item["Parent_Proprietary_ID"] = parent.id
            item["Parent_ISBN"] = parent.isbn.join(", ")
            item["Parent_Print_ISSN"] = ""
            item["Parent_Online_ISSN"] = ""
            item["Parent_URL"] = Rails.application.routes.url_helpers.hyrax_monograph_url(parent.id)
            item["Component_Title"] = comp_title
            item["Data_Type"] = find_data_type(presenter, section)
            item["Section_Type"] = section
            item["YOP"] = @params.yop
            item["Access_Type"] = access_type
            item["Access_Method"] = @params.access_method
            item["Metric_Type"] = metric_type
            # item["Reporting_Period_Total"] = reporting_period_total
            item["Reporting_Period_Total"] = results.values.filter_map { |r| r[metric_type.downcase][access_type.downcase][[parent_noid, noid, section, comp_title]] }.sum
            results.each do |month, result|
              item[month] = result[metric_type.downcase][access_type.downcase][[parent_noid, noid, section, comp_title]] || 0
            end

            items << item
          end
        end
      end

      items = [[]] if items.empty?

      { header: header, items: items }
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

    def unique_results(results)
      ur = {}
      results.values.each do |result|
        @params.metric_types.each do |metric_type|
          @params.access_types.each do |access_type|
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

    def unique_noids(results)
      noids = []
      results.values.each do |result|
        @params.metric_types.each do |metric_type|
          @params.access_types.each do |access_type|
            noids.concat(result[metric_type.downcase][access_type.downcase].keys.map { |r| r[1] })
          end
        end
      end
      noids.uniq
    end

    def unique_parent_noids(results)
      parent_noids = []
      results.values.each do |result|
        @params.metric_types.each do |metric_type|
          @params.access_types.each do |access_type|
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

    def results_by_month
      results = ActiveSupport::OrderedHash.new
      this_month = @params.start_date
      until this_month > @params.end_date
        item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
        results[item_month] = {}
        @params.metric_types.each do |metric_type|
          results[item_month][metric_type.downcase] = {}
          @params.access_types.each do |access_type|
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

    def header
      institution_name = if @params.institution == '*'
                           "All Institutions"
                         else
                           Greensub::Institution.where(identifier: @params.institution).first&.name
                         end
      {
        Report_Name: @params.report_title,
        Report_ID: @params.report_type.upcase,
        Release: "5",
        Institution_Name: institution_name,
        Institution_ID: @params.institution,
        Metric_Types: @params.metric_types.join("; "),
        Report_Filters: "Data_Type=#{@params.data_type}; Access_Type=#{@params.access_types.join('; ')}; Access_Method=#{@params.access_method}",
        Report_Attributes: "",
        Exceptions: "",
        Reporting_Period: "#{@params.start_date.year}-#{@params.start_date.month} to #{@params.end_date.year}-#{@params.end_date.month}",
        Created: Time.zone.today.iso8601,
        Created_By: "Fulcrum/#{@params.press.name}"
      }
    end
  end
end
