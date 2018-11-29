# frozen_string_literal: true

module CounterReporter
  class TitleReport
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def report
      results = results_by_month
      items = []

      monograph_presenters(unique_parent_noids(results)).sort_by(&:title).each do |presenter|
        # should "yop"/year of publication be in the counter_report table?
        next if @params.yop.present? && @params.yop != presenter.date_created.first
        @params.metric_types.each do |metric_type|
          @params.access_types.each do |access_type|
            item = ActiveSupport::OrderedHash.new
            item["Title"] = presenter.title
            item["Publisher"] = presenter.publisher.first
            item["Publisher_ID"] = ""
            item["Platform"] = "Fulcrum/#{@params.press.name}"
            item["DOI"] = presenter.citable_link
            item["Proprietary_ID"] = presenter.id
            item["ISBN"] = presenter.isbn.join("; ")
            item["Print_ISSN"] = ""
            item["Online_ISSN"] = ""
            item["URI"] = Rails.application.routes.url_helpers.hyrax_monograph_url(presenter.id)
            item["Access_Type"] = access_type if @params.report_type == 'tr_b3'
            item["Metric_Type"] = metric_type
            item["Reporting_Period_Total"] = results.values.map { |r| r[metric_type.downcase][access_type.downcase][presenter.id] }.compact.sum
            results.each do |result|
              item[result[0]] = result[1][metric_type.downcase][access_type.downcase][presenter.id] || 0
            end

            items << item
          end
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

    def unique_parent_noids(results)
      parent_noids = []
      results.values.each do |result|
        @params.metric_types.each do |metric_type|
          @params.access_types.each do |access_type|
            parent_noids.concat(result[metric_type.downcase][access_type.downcase].keys)
          end
        end
      end
      parent_noids.uniq
    end

    def monograph_presenters(noids)
      # in hyrax PresenterFactory.load_docs has a hard coded limit of 1000 rows
      presenters = []
      until noids.empty?
        presenters.concat(Hyrax::PresenterFactory.build_for(ids: noids.shift(999), presenter_class: Hyrax::MonographPresenter, presenter_args: nil))
      end
      presenters
    end

    def total_item_investigations(month, access_type = @params.access_types.first)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .turnaway
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .group('parent_noid')
                   .count
    end

    def unique_item_investigations(month, access_type = @params.access_types.first)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .turnaway
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique
                   .group('parent_noid')
                   .count
    end

    def unique_title_investigations(month, access_type = @params.access_types.first)
      CounterReport.institution(@params.institution)
                   .investigations
                   .access_type(access_type)
                   .turnaway
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique_by_title
                   .group('parent_noid')
                   .count
    end

    def total_item_requests(month, access_type = @params.access_types.first)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .turnaway
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .group('parent_noid')
                   .count
    end

    def unique_item_requests(month, access_type = @params.access_types.first)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .turnaway
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique
                   .group('parent_noid')
                   .count
    end

    def unique_title_requests(month, access_type = @params.access_types.first)
      CounterReport.institution(@params.institution)
                   .requests
                   .access_type(access_type)
                   .turnaway
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .unique_by_title
                   .group('parent_noid')
                   .count
    end

    def no_license(month, _access_type)
      CounterReport.institution(@params.institution)
                   .turnaway("No_License")
                   .start_date(month.beginning_of_month)
                   .end_date(month.end_of_month)
                   .press(@params.press.id)
                   .group('parent_noid')
                   .count
    end

    def limit_exceeded(_month, _access_type)
      raise "The Limit_Exceeded turnaway metric is not currently tracked/implemented"
    end

    def header
      {
        Report_Name: @params.report_title,
        Report_ID: @params.report_type.upcase,
        Release: "5",
        Institution_Name: Institution.where(identifier: @params.institution).first&.name,
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
