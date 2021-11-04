# frozen_string_literal: true

module CounterReporter
  class PlatformReport
    attr_reader :params

    def initialize(params)
      @params = params
    end

    # rubocop:disable Metrics/BlockLength
    def report # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      show_data_type = @params.attributes_to_show.include?("Data_Type") && @params.report_type == 'pr'
      show_access_type = @params.attributes_to_show.include?("Access_Type") && @params.report_type == 'pr'
      show_access_method = @params.attributes_to_show.include?("Access_Method") && @params.report_type == 'pr'

      results = results_by_month
      items = []

      access_method = @params.access_methods.first

      [@params.press].each do |platform|
        metric_type_reporting_monthly_total = {}
        @params.metric_types.each do |metric_type|
          metric_reporting_period_total = 0
          metric_type_reporting_monthly_total[metric_type] = {}
          metric_data_type_reporting_monthly_total = {}
          metric_access_type_reporting_period_total = {}
          metric_access_type_reporting_monthly_total = {}
          @params.data_types.each do |data_type|
            metric_data_type_reporting_period_total = 0
            metric_data_type_reporting_monthly_total[data_type] ||= {}
            @params.access_types.each do |access_type|
              metric_access_type_reporting_period_total[access_type] ||= 0
              metric_access_type_reporting_monthly_total[access_type] ||= {}
              item = ActiveSupport::OrderedHash.new
              item["Platform"] = "#{platform.name}"
              item["Data_Type"] = data_type if show_data_type
              item["Access_Type"] = access_type if show_access_type
              item["Access_Method"] = access_method if show_access_method
              item["Metric_Type"] = metric_type
              item["Reporting_Period_Total"] = results.values.filter_map { |r| r[metric_type.downcase][access_type.downcase] }.sum
              metric_access_type_reporting_period_total[access_type] += item["Reporting_Period_Total"]
              metric_data_type_reporting_period_total += item["Reporting_Period_Total"]
              metric_reporting_period_total += item["Reporting_Period_Total"]
              unless @params.exclude_monthly_details
                results.each do |result|
                  item[result[0]] = result[1][metric_type.downcase][access_type.downcase] || 0
                  metric_access_type_reporting_monthly_total[access_type][result[0]] ||= 0
                  metric_access_type_reporting_monthly_total[access_type][result[0]] += item[result[0]]
                  metric_data_type_reporting_monthly_total[data_type][result[0]] ||= 0
                  metric_data_type_reporting_monthly_total[data_type][result[0]] += item[result[0]]
                end
              end

              items << item if show_data_type && show_access_type
            end
            item = ActiveSupport::OrderedHash.new
            item["Platform"] = "#{platform.name}"
            item["Data_Type"] = data_type if show_data_type
            item["Access_Type"] = '' if show_access_type
            item["Access_Method"] = access_method if show_access_method
            item["Metric_Type"] = metric_type
            item["Reporting_Period_Total"] = metric_data_type_reporting_period_total

            unless @params.exclude_monthly_details
              results.each do |result|
                item[result[0]] = metric_data_type_reporting_monthly_total[data_type][result[0]]
                metric_type_reporting_monthly_total[metric_type][result[0]] ||= 0
                metric_type_reporting_monthly_total[metric_type][result[0]] += item[result[0]]
              end
            end

            items << item if show_data_type && !show_access_type
          end
          item = ActiveSupport::OrderedHash.new
          item["Platform"] = "Fulcrum/#{platform.name}"
          item["Data_Type"] = '' if show_data_type
          item["Access_Type"] = '' if show_access_type
          item["Access_Method"] = access_method if show_access_method
          item["Metric_Type"] = metric_type
          item["Reporting_Period_Total"] = metric_reporting_period_total

          unless @params.exclude_monthly_details
            results.each do |result|
              item[result[0]] = metric_type_reporting_monthly_total[metric_type][result[0]]
            end
          end

          items << item unless show_data_type || show_access_type

          if !show_data_type && show_access_type
            @params.access_types.each do |access_type|
              item = ActiveSupport::OrderedHash.new
              item["Platform"] = "#{platform.name}"
              item["Access_Type"] = access_type
              item["Access_Method"] = access_method if show_access_method
              item["Metric_Type"] = metric_type
              item["Reporting_Period_Total"] = metric_access_type_reporting_period_total[access_type]

              unless @params.exclude_monthly_details
                results.each do |result|
                  item[result[0]] = metric_access_type_reporting_monthly_total[access_type][result[0]]
                end
              end

              items << item
            end
          end
        end
      end

      items = [[]] if items.empty?

      { header: header, items: items }
    end
    # rubocop:enable Metrics/BlockLength

    def results_by_month
      results = ActiveSupport::OrderedHash.new
      this_month = @params.start_date
      until this_month > @params.end_date
        item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
        results[item_month] = {}
        @params.metric_types.each do |metric_type|
          results[item_month][metric_type.downcase] = {}
          metric_type_total = 0
          @params.access_types.each do |access_type|
            access_type_total = send(metric_type.downcase, this_month, access_type)
            results[item_month][metric_type.downcase][access_type.downcase] = access_type_total
            metric_type_total += access_type_total
          end
          results[item_month][metric_type.downcase]['total'] = metric_type_total
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
                           institution_ids << 'ID:' + institution.identifier.to_s
                           institution_ids << 'ROR:' + institution.ror_id.to_s if institution.ror_id.present?
                           institution.name
                         end
      report_filters = []
      report_filters << "Platform=#{@params.platforms.join('|')}"
      if @params.report_type == 'pr'
        report_filters << "Data_Type=#{@params.data_types.join('|')}" if @params.data_types.count == 1
        report_filters << "Access_Type=#{@params.access_types.join('|')}" if @params.access_types.count == 1
      end
      report_filters << "Access_Method=#{@params.access_methods.join('|')}" if @params.access_methods.count == 1
      report_attributes = []
      report_attributes << "Attributes_To_Show=#{@params.attributes_to_show.join('|')}" if @params.attributes_to_show.present?
      report_attributes << "Exclude_Monthly_Details=True" if @params.exclude_monthly_details
      {
        Report_Name: @params.report_title,
        Report_ID: @params.report_type.upcase,
        Release: "5",
        Institution_Name: institution_name,
        Institution_ID: institution_ids.join("; "),
        Metric_Types: @params.metric_types.join("; "),
        Report_Filters: report_filters.join("; "),
        Report_Attributes: report_attributes.join("; "),
        Exceptions: "",
        Reporting_Period: "#{@params.start_date.year}-#{@params.start_date.month} to #{@params.end_date.year}-#{@params.end_date.month}",
        Created: Time.zone.today.iso8601,
        Created_By: "Fulcrum/#{@params.press.name}"
      }
    end
  end
end
