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
  class PlatformReport
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def report # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
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

      results = results_by_month(metric_types, access_types)
      items = []

      metric_types.each do |metric_type|
        running_totals = { total: 0, monthly_totals: {} }
        access_types.each do |access_type|
          item = new_item(results, metric_type, data_type, access_type, access_method, running_totals)
          next if @params.counter_5_report && item["Reporting_Period_Total"] == 0

          items << item if @params.attributes_to_show.include?('Access_Type')
        end
        item = new_item(results, metric_type, data_type, nil, access_method, running_totals)
        next if @params.counter_5_report && item["Reporting_Period_Total"] == 0

        items << item unless @params.attributes_to_show.include?('Access_Type')
      end

      items = [[]] if items.empty?

      { header: header(metric_types), items: items }
    end

    def new_item(results, metric_type, data_type, access_type, access_method, running_totals) # rubocop:disable Metrics/ParameterLists
      item = ActiveSupport::OrderedHash.new
      item["Platform"] = "Fulcrum/#{@params.press.name}"
      item["Data_Type"] = data_type if @params.attributes_to_show.include?('Data_Type')
      item["Access_Type"] = access_type if @params.attributes_to_show.include?('Access_Type')
      item["Access_Method"] = access_method if @params.attributes_to_show.include?('Access_Method')
      item["Metric_Type"] = metric_type
      if access_type.present?
        item["Reporting_Period_Total"] = results.values.filter_map { |r| r[metric_type.downcase][access_type.downcase] }.sum
        running_totals[:total] += item["Reporting_Period_Total"]
      else
        item["Reporting_Period_Total"] = running_totals[:total]
      end
      if @params.include_monthly_details
        results.each do |result|
          if access_type.present?
            item[result[0]] = result[1][metric_type.downcase][access_type.downcase] || 0
            running_totals[:monthly_totals][result[0]] ||= 0
            running_totals[:monthly_totals][result[0]] += item[result[0]]
          else
            item[result[0]] = running_totals[:monthly_totals][result[0]]
          end
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
      report_filters << "Platform=#{@params.platforms.join('|')}" if @params.platforms.present?
      report_filters << "Data_Type=#{@params.data_types.join('|')}" if @params.data_types.present?
      report_filters << "Access_Type=#{@params.access_types.join('|')}" if @params.access_types.present?
      report_filters << "Access_Method=#{@params.access_methods.join('|')}" if @params.access_methods.present?
      report_attributes = []
      report_attributes << "Attributes_To_Show=#{@params.attributes_to_show.join('|')}" if @params.attributes_to_show.present?
      report_attributes << "Exclude_Monthly_Details=True" unless @params.include_monthly_details
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

    def searches_platform(month, access_type)
      CounterReport.institution(@params.institution)
                   .searches
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .count
    end

    def total_item_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .count
    end

    def unique_item_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique
                   .count
    end

    def unique_title_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique_by_title
                   .count
    end

    def total_item_requests(month, access_type)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .count
    end

    def unique_item_requests(month, access_type)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique
                   .count
    end

    def unique_title_requests(month, access_type)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique_by_title
                   .count
    end
  end
end
