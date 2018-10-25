# frozen_string_literal: true

module CounterReporter
  class TitleParams
    attr_reader :report_type, :start_date, :end_date, :press, :institution,
                :metric_types, :data_type, :access_types, :access_method, :yop,
                :report_title, :errors

    def initialize(report_type, params)
      @report_type = report_type
      @start_date  = make_start_date(params)
      @end_date    = make_end_date(params)
      @press       = params[:press] || nil
      @institution = params[:institution]
      @errors      = []

      case @report_type
      when 'tr_b1'
        tr_b1
      when 'tr'
        tr(params)
      when 'tr_b2'
        tr_b2
      when 'tr_b3'
        tr_b3
      end
    end

    def validate!
      institution? && allowed_metric_types? && allowed_access_types?
    end

    def institution?
      @errors << "You must provide an Institution" if @institution.nil?
      return false if @errors.present?
      true
    end

    def allowed_metric_types?
      allowed_types = %w[Total_Item_Investigations Unique_Item_Investigations Unique_Title_Investigations
                         Total_Item_Requests Unique_Item_Requests Unique_Title_Requests
                         No_License Limit_Exceeded]
      @metric_types.each do |metric_type|
        unless allowed_types.include?(metric_type)
          @errors << "Metric Type: '#{metric_type}' is not allowed"
        end
      end
      return false if @errors.present?
      true
    end

    def allowed_access_types?
      @access_types.each do |access_type|
        unless %w[Controlled OA_Gold].include?(access_type)
          @errors << "Access Type: '#{access_type}' is not allowed"
        end
      end
      return false if @errors.present?
      true
    end

    private

      def make_start_date(params)
        if params[:start_date].present?
          Date.parse(params[:start_date])
        else
          CounterReport.where(institution: params[:institution]).first&.created_at || Date.parse("2018-08-01")
        end
      end

      def make_end_date(params)
        if params[:end_date].present?
          Date.parse(params[:end_date])
        else
          Time.now.utc
        end
      end

      def tr_b1
        @report_title = 'Book Requests (Excluding OA_Gold)'
        @metric_types = ['Total_Item_Requests', 'Unique_Title_Requests']
        @data_type = 'Book'
        @access_types = ['Controlled']
        @access_method = 'Regular'
      end

      def tr(params)
        @report_title = 'Title Master Report'
        @metric_types = [params[:metric_type]].flatten
        @data_type = params[:data_type] || 'Book'
        @access_types = [params[:access_type]].flatten
        @access_method = params[:access_method] || 'Regular'
        @yop = params[:yop] || nil
      end

      def tr_b2
        @report_title = 'Access Denied by Book'
        @metric_types = ['No_License']
        @data_type = 'Book'
        @access_types = ['Controlled']
        @access_method = 'Regular'
      end

      def tr_b3
        @report_title = 'Book Usage by Access Type'
        @metric_types = %w[Total_Item_Investigations Unique_Item_Investigations Unique_Title_Investigations
                           Total_Item_Requests Unique_Item_Requests Unique_Title_Requests]
        @data_type = 'Book'
        @access_types = %w[Controlled OA_Gold]
        @access_method = 'Regular'
      end
  end
end
