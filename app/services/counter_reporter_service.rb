# frozen_string_literal: true

class CounterReporterService
  # See notes in HELIO-1376
  # https://tools.lib.umich.edu/jira/browse/HELIO-1376?focusedCommentId=898167&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-898167

  def self.pr_p1(params) # rubocop:disable Metrics/CyclomaticComplexity
    # Example pr_p1 report:
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1932253188
    start_date  = Date.parse(params[:start_date]) || CounterReport.first.created_at
    end_date    = Date.parse(params[:end_date]) || Time.now.utc
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
      Reporting_Period: "#{start_date} to #{end_date}",
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
end
