# frozen_string_literal: true

class CounterReporterService
  # See notes in HELIO-1376
  # https://tools.lib.umich.edu/jira/browse/HELIO-1376?focusedCommentId=898167&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-898167

  def self.pr_p1(params) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # Example pr_p1 report:
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1932253188
    start_date  = if params[:start_date].present?
                    Date.parse(params[:start_date])
                  else
                    CounterReport.first.created_at
                  end
    end_date    = if params[:end_date].present?
                    Date.parse(params[:end_date])
                  else
                    Time.now.utc
                  end
    press       = params[:press] || nil
    institution = params[:institution]

    header = {
      Report_Name: "Platform Usage",
      Report_ID: "PR_P1",
      Release: "5",
      Institution_Name: Institution.where(identifier: institution).first&.name,
      Institution_ID: institution,
      Metric_Types: "Total_Item_Requests; Unique_Item_Requests; Unique_Title_Requests",
      Report_Filters: "Access_Type=Controlled; Access_Method=Regular",
      Report_Attributes: "",
      Exceptions: "",
      Reporting_Period: "#{start_date.year}-#{start_date.month} to #{end_date.year}-#{end_date.month}",
      Created: Time.zone.today.iso8601,
      Created_By: "Fulcrum"
    }

    items = []

    # Total_Item_Requests
    item = ActiveSupport::OrderedHash.new
    item["Platform"] = "Fulcrum"
    item["Metric_Type"] = "Total_Item_Requests"
    item["Reporting_Period_Total"] = CounterReport.institution(institution)
                                                  .requests
                                                  .controlled
                                                  .start_date(start_date)
                                                  .end_date(end_date)
                                                  .press(press)
                                                  .count
    this_month = start_date
    until this_month > end_date
      item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
      item[item_month] = CounterReport.institution(institution)
                                      .requests
                                      .controlled
                                      .where("YEAR(created_at) = ? and MONTH(created_at) = ?", this_month.year, this_month.month)
                                      .press(press)
                                      .count
      this_month = this_month.next_month
    end

    items << item

    # Unique_Item_Requests
    item = ActiveSupport::OrderedHash.new
    item["Platform"] = "Fulcrum"
    item["Metric_Type"] = "Unique_Item_Requests"
    item["Reporting_Period_Total"] = CounterReport.institution(institution)
                                                  .requests
                                                  .controlled
                                                  .unique
                                                  .start_date(start_date)
                                                  .end_date(end_date)
                                                  .press(press)
                                                  .count

    this_month = start_date
    until this_month > end_date
      item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
      item[item_month] = CounterReport.institution(institution)
                                      .requests
                                      .controlled
                                      .unique
                                      .where("YEAR(created_at) = ? and MONTH(created_at) = ?", this_month.year, this_month.month)
                                      .press(press)
                                      .count
      this_month = this_month.next_month
    end

    items << item

    # Unique_Title_Requests
    item = ActiveSupport::OrderedHash.new
    item["Platform"] = "Fulcrum"
    item["Metric_Type"] = "Unique_Title_Requests"
    item["Reporting_Period_Total"] = CounterReport.institution(institution)
                                                  .requests
                                                  .controlled
                                                  .unique_by_title
                                                  .start_date(start_date)
                                                  .end_date(end_date)
                                                  .press(press)
                                                  .count
    this_month = start_date
    until this_month > end_date
      item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
      item[item_month] = CounterReport.institution(institution)
                                      .requests
                                      .controlled
                                      .unique_by_title
                                      .where("YEAR(created_at) = ? and MONTH(created_at) = ?", this_month.year, this_month.month)
                                      .press(press)
                                      .count
      this_month = this_month.next_month
    end

    items << item

    { header: header, items: items }
  end

  def self.tr_b1(params) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    # Example tr_b1 report:
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1559300549
    start_date  = if params[:start_date].present?
                    Date.parse(params[:start_date])
                  else
                    CounterReport.first.created_at
                  end
    end_date    = if params[:end_date].present?
                    Date.parse(params[:end_date])
                  else
                    Time.now.utc
                  end
    press       = params[:press] || nil
    institution = params[:institution]

    header = {
      Report_Name: "Book Requests (Excluding OA_Gold)",
      Report_ID: "TR_B1",
      Release: "5",
      Institution_Name: Institution.where(identifier: institution).first&.name,
      Institution_ID: institution,
      Metric_Types: "Total_Item_Requests; Unique_Title_Requests",
      Report_Filters: "Data_Type=Book; Access_Type=Controlled; Access_Method=Regular",
      Report_Attributes: "",
      Exceptions: "",
      Reporting_Period: "#{start_date.year}-#{start_date.month} to #{end_date.year}-#{end_date.month}",
      Created: Time.zone.today.iso8601,
      Created_By: "Fulcrum"
    }

    results = ActiveSupport::OrderedHash.new
    this_month = start_date
    until this_month > end_date
      item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
      results[item_month] = {}
      results[item_month][:total_item_requests] = CounterReport.institution(institution)
                                                               .requests
                                                               .controlled
                                                               .start_date(this_month.beginning_of_month)
                                                               .end_date(this_month.end_of_month)
                                                               .press(press)
                                                               .group('parent_noid')
                                                               .count
      results[item_month][:unique_title_requests] = CounterReport.institution(institution)
                                                                 .requests
                                                                 .controlled
                                                                 .start_date(this_month.beginning_of_month)
                                                                 .end_date(this_month.end_of_month)
                                                                 .press(press)
                                                                 .unique_by_title
                                                                 .group('parent_noid')
                                                                 .count
      this_month = this_month.next_month
    end

    unique_parent_noids = results.values.map { |r| r[:total_item_requests].keys + r[:unique_title_requests].keys }.flatten.uniq

    items = []
    monograph_presenters(unique_parent_noids).sort_by(&:title).each do |presenter|
      # total item requests
      item = ActiveSupport::OrderedHash.new
      item["Title"] = presenter.title
      item["Publisher"] = presenter.publisher.first
      item["Publisher_ID"] = ""
      item["Platform"] = "Fulcrum"
      item["DOI"] = presenter.citable_link
      item["Proprietary_ID"] = presenter.id
      item["ISBN"] = presenter.isbn.join("; ")
      item["Print_ISSN"] = ""
      item["Online_ISSN"] = ""
      item["URI"] = Rails.application.routes.url_helpers.hyrax_monograph_url(presenter.id)
      item["Metric_Type"] = "Total_Item_Requests"
      item["Reporting_Period_Total"] = results.values.map { |r| r[:total_item_requests][presenter.id] }.compact.sum
      results.each do |result|
        item[result[0]] = result[1][:total_item_requests][presenter.id] || 0
      end

      items << item

      # unique title requests
      item = ActiveSupport::OrderedHash.new
      item["Title"] = presenter.title
      item["Publisher"] = presenter.publisher.first
      item["Publisher_ID"] = ""
      item["Platform"] = "Fulcrum"
      item["DOI"] = presenter.citable_link
      item["Proprietary_ID"] = presenter.id
      item["ISBN"] = presenter.isbn.join("; ")
      item["Print_ISSN"] = ""
      item["Online_ISSN"] = ""
      item["URI"] = Rails.application.routes.url_helpers.hyrax_monograph_url(presenter.id)
      item["Metric_Type"] = "Unique_Title_Requests"
      item["Reporting_Period_Total"] = results.values.map { |r| r[:unique_title_requests][presenter.id] }.compact.sum
      results.each do |result|
        item[result[0]] = result[1][:unique_title_requests][presenter.id] || 0
      end

      items << item
    end

    items = [[]] if items.empty?

    { header: header, items: items }
  end

  def self.monograph_presenters(unique_parent_noids)
    # in hyrax PresenterFactory.load_docs has a hard coded limit of 1000 rows
    presenters = []
    until unique_parent_noids.empty?
      presenters.concat(Hyrax::PresenterFactory.build_for(ids: unique_parent_noids.shift(999), presenter_class: Hyrax::MonographPresenter, presenter_args: nil))
    end
    presenters
  end

  def self.csv(report)
    # CSV for COUNTER is just weird and not normal
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1932253188
    CSV.generate({}) do |csv|
      row = []
      # header rows
      report[:header].each do |k, v|
        row << k
        row << v
        1.upto(report[:items][0].length - 2).each do
          row << ""
        end
        csv << row
        row = []
      end
      # empty row
      csv << 1.upto(report[:items][0].length).map { "" }
      # items
      if report[:items][0].empty?
        csv << ["Report is empty", ""]
      else
        # item rows header
        report[:items][0].each do |k, _|
          row << k
        end
        csv << row
        # items
        row = []
        report[:items].each do |item|
          item.each do |_, v|
            row << v
          end
          csv << row
          row = []
        end
      end
    end
  end
end
