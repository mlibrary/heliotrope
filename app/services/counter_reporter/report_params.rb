# frozen_string_literal: true

module CounterReporter
  class ReportParams
    attr_reader :report_type, :start_date, :end_date, :institution, :press, :platforms,
                :metric_types, :data_types, :access_types, :access_methods, :yop,
                :attributes_to_show, :exclude_monthly_details, :report_title, :errors

    def initialize(report_type, params) # rubocop:disable Metrics/CyclomaticComplexity
      @report_type = report_type
      @start_date  = make_start_date(params)
      @end_date    = make_end_date(params)
      @institution = params[:institution]
      @press       = Press.where(id: params[:press]).first
      @yop         = nil
      @attributes_to_show = []
      @attributes_to_show << "Data_Type" if params[:show_data_type]
      @attributes_to_show << "Access_Type" if params[:show_access_type]
      @attributes_to_show << "Access_Method" if params[:show_access_method]
      @exclude_monthly_details = params[:exclude_monthly_details].present?
      @errors      = []

      set_platforms

      case @report_type
      when 'pr'
        pr(params)
      when 'pr_p1'
        pr_p1
      when 'tr'
        tr(params)
      when 'tr_b1'
        tr_b1
      when 'tr_b2'
        tr_b2
      when 'tr_b3'
        tr_b3
      when 'ir'
        ir(params)
      when 'ir_m1'
        ir_m1
      when 'counter4_br2'
        counter4_br2
      end
    end

    def validate!
      institution? && press? && allowed_data_types? && allowed_access_types? && allowed_access_methods? && allowed_metric_types?
    end

    def institution?
      @errors << "You must provide an Institution" if @institution.nil?
      return false if @errors.present?
      true
    end

    def press?
      @errors << "You must provide a Press" if @press.nil?
      return false if @errors.present?
      true
    end



    def allowed_data_types?
      allowed_values = %w[Book Multimedia]
      allowed_values?('Data Type', @data_types, allowed_values)
    end

    def allowed_access_types?
      allowed_values = %w[Controlled OA_Gold]
      allowed_values?('Access Type', @access_types, allowed_values)
    end

    def allowed_access_methods?
      allowed_values = %w[Regular]
      allowed_values?('Access Method', @access_methods, allowed_values)
    end

    def allowed_metric_types?
      allowed_values = %w[Searches_Platform
                          Total_Item_Investigations Unique_Item_Investigations Unique_Title_Investigations
                          Total_Item_Requests Unique_Item_Requests Unique_Title_Requests
                          No_License Limit_Exceeded]
      allowed_values?('Metric Type', @metric_types, allowed_values)
    end

    private

      def set_platforms
        @platforms = []

        if @press.present?
          # @platforms = @press.children.map(&:subdomain)
          # @platforms.unshift(@press.subdomain)
          @platforms = [@press.subdomain]
        end

        @platforms
      end

      def allowed_values?(label, values, allowed_values)
        values.each do |value|
          unless allowed_values.include?(value)
            @errors << "#{label}: '#{value}' is not allowed"
          end
        end
        return false if @errors.present?

        true
      end

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

      def pr(params)
        @report_title = 'Platform Master Report'
        @metric_types = params[:metric_types] || [params[:metric_type]].flatten
        @data_types = params[:data_types] || [params[:data_type]].flatten
        @access_types = params[:access_types] || [params[:access_type]].flatten
        @access_methods = params[:access_methods] || [params[:access_method]].flatten
        @yop = params[:yop]
      end

      def pr_p1
        @report_title = 'Platform Usage'
        @metric_types = %w[Searches_Platform Total_Item_Requests Unique_Item_Requests Unique_Title_Requests]
        @data_types = %w[Book]
        @access_types = %w[Controlled]
        @access_methods = %w[Regular]
      end

      def tr(params)
        @report_title = 'Title Master Report'
        @metric_types = [params[:metric_type]].flatten
        @data_types = [params[:data_type]].flatten
        @access_types = [params[:access_type]].flatten
        @access_methods = [params[:access_method]].flatten
        @yop = params[:yop]
      end

      def tr_b1
        @report_title = 'Book Requests (Excluding OA_Gold)'
        @metric_types = %w[Total_Item_Requests Unique_Title_Requests]
        @data_types = %w[Book]
        @access_types = %w[Controlled]
        @access_methods = %w[Regular]
      end

      def tr_b2
        @report_title = 'Access Denied by Book'
        @metric_types = %w[No_License]
        @data_types = %w[Book]
        @access_types = %w[Controlled]
        @access_methods = %w[Regular]
      end

      def tr_b3
        @report_title = 'Book Usage by Access Type'
        @metric_types = %w[Total_Item_Investigations Unique_Item_Investigations Unique_Title_Investigations
                           Total_Item_Requests Unique_Item_Requests Unique_Title_Requests]
        @data_types = %w[Book]
        @access_types = %w[Controlled OA_Gold]
        @access_methods = %w[Regular]
      end

      def ir(params)
        @report_title = 'Item Master Report'
        @metric_types = [params[:metric_type]].flatten
        @data_types = [params[:data_type]].flatten
        @access_types = [params[:access_type]].flatten
        @access_methods = [params[:access_method]].flatten
        @yop = params[:yop]
      end

      def ir_m1
        @report_title = 'Multimedia Item Requests'
        @metric_types = %w[Total_Item_Requests]
        @data_types = %w[Multimedia]
        @access_types = %w[OA_Gold Controlled]
        @access_methods = %w[Regular]
      end

      def counter4_br2
        # Ideally this is very temporary
        # COUNTER4 doesn't have metric types, but according to the COUNTER 5 spec this is:
        # "R5 equivalent:  Total_Item_Requests AND Data_Type=Book AND Section_Type=Chapter|Section"
        # So... sort of a Total_Item_Requests. We'll use that to get past validation but it's actually
        # custom
        @metric_types = %w[Total_Item_Requests]
        @data_types = %w[Book]
        @access_types = %w[Controlled]
        @access_methods = %w[Regular]
      end
  end
end
