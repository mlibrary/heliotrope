# frozen_string_literal: true

module CounterReporter
  class PlatformReport
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def report # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      results = results_by_month
      items = []

      @params.metric_types.each do |metric_type|
        @params.access_types.each do |access_type|
          item = ActiveSupport::OrderedHash.new
          item["Platform"] = "Fulcrum/#{@params.press.name}"
          if @params.report_type == 'pr'
            item["Data_Type"] = @params.data_type
            item["Access_Type"] = access_type
            item["Access_Method"] = @params.access_method
          end
          item["Metric_Type"] = metric_type
          item["Reporting_Period_Total"] = results.values.filter_map { |r| r[metric_type.downcase][access_type.downcase] }.sum
          results.each do |result|
            item[result[0]] = result[1][metric_type.downcase][access_type.downcase] || 0
          end

          items << item
        end
      end

      items = [[]] if items.empty?

      { header: header, items: items }
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
                   .press(@params.press.id)
                   .count
    end

    def unique_item_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .unique
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .count
    end

    def unique_title_investigations(month, access_type)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .unique_by_title
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
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
                   .unique
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .count
    end

    def unique_title_requests(month, access_type)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .unique_by_title
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .count
    end

    def header
      institution_ids = []
      institution_name = if @params.institution == '*'
                           institution_ids << '*'
                           "All Institutions"
                         else
                           institution = Greensub::Institution.find_by(identifier: @params.institution)
                           institution_ids << institution.identifier
                           institution_ids << institution.ror_id if institution.ror_id.present?
                           institution.name
                         end
      {
        Report_Name: @params.report_title,
        Report_ID: @params.report_type.upcase,
        Release: "5",
        Institution_Name: institution_name,
        Institution_ID: institution_ids.join("; "),
        Metric_Types: @params.metric_types.join("; "),
        Report_Filters: "Access_Type=#{@params.access_types.join('; ')}; Access_Method=#{@params.access_method}",
        Report_Attributes: "",
        Exceptions: "",
        Reporting_Period: "#{@params.start_date.year}-#{@params.start_date.month} to #{@params.end_date.year}-#{@params.end_date.month}",
        Created: Time.zone.today.iso8601,
        Created_By: "Fulcrum/#{@params.press.name}"
      }
    end
  end
end
