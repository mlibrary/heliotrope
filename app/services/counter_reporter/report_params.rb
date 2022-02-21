# frozen_string_literal: true

module CounterReporter
  class ReportParams
    attr_reader :report_type, :start_date, :end_date, :press, :institution, :platforms,
                :metric_types, :data_type, :access_types, :access_method, :yop,
                :report_title, :errors

    def initialize(report_type, params) # rubocop:disable Metrics/CyclomaticComplexity
      @report_type = report_type
      @start_date  = make_start_date(params)
      @end_date    = make_end_date(params)
      @press       = Press.where(id: params[:press]).first
      @institution = params[:institution]
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
      press? && institution? && allowed_metric_types? && allowed_access_types?
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

    def allowed_metric_types?
      allowed_types = %w[Searches_Platform Total_Item_Investigations Unique_Item_Investigations Unique_Title_Investigations
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

      def set_platforms
        @platforms = []

        if @press.present?
          # @platforms = @press.children.map(&:subdomain)
          # @platforms.unshift(@press.subdomain)
          @platforms = [@press.subdomain]
        end

        @platforms
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
        @metric_types = [params[:metric_type]].flatten
        @data_type = params[:data_type] || 'Book'
        @access_types = [params[:access_type]].flatten
        @access_method = params[:access_method] || 'Regular'
        @yop = params[:yop] || nil
      end

      def pr_p1
        @report_title = 'Platform Usage'
        @metric_types = ['Searches_Platform', 'Total_Item_Requests', 'Unique_Item_Requests', 'Unique_Title_Requests']
        @access_types = ['Controlled']
        @access_method = 'Regular'
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

      def ir(params)
        @report_title = 'Item Master Report'
        @metric_types = [params[:metric_type]].flatten
        @data_type = params[:data_type] || 'Book'
        @access_types = [params[:access_type]].flatten
        @access_method = params[:access_method] || 'Regular'
        @yop = params[:yop] || nil
      end

      def ir_m1
        @report_title = 'Multimedia Item Requests'
        @metric_types = ['Total_Item_Requests']
        @data_type = 'Multimedia'
        @access_types = ['OA_Gold', 'Controlled']
        @access_method = 'Regular'
      end

      def counter4_br2
        # Ideally this is very temporary
        # COUNTER4 doesn't have metric types, but according to the COUNTER 5 spec this is:
        # "R5 equivalent:  Total_Item_Requests AND Data_Type=Book AND Section_Type=Chapter|Section"
        # So... sort of a Total_Item_Requests. We'll use that to get past validation but it's actually
        # custom
        @metric_types = ["Total_Item_Requests"]
        @access_types = ["Controlled"]
      end
  end
end
