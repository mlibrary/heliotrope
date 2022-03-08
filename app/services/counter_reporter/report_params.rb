# frozen_string_literal: true

module CounterReporter
  class ReportParams # rubocop:disable Metrics/ClassLength
    attr_reader :report_type, :counter_5_report, :institution, :start_date, :end_date, :press, :platforms,
                :data_types, :section_types, :yop, :access_types, :access_methods, :metric_types,
                :attributes_to_show, :include_parent_details, :include_component_details, :include_monthly_details,
                :exclude_monthly_details, :report_title, :errors

    def initialize(report_type, params) # rubocop:disable Metrics/CyclomaticComplexity
      @report_type = report_type
      @counter_5_report = params[:counter_5_report].present?
      @institution = params[:institution]
      @start_date = make_start_date(params)
      @end_date = make_end_date(params)
      @press = Press.where(id: params[:press]).first
      @data_types = params[:data_types] || [params[:data_type]].flatten.compact
      @section_types = params[:section_types] || [params[:section_type]].flatten.compact
      @yop = params[:yop] || nil
      @access_types = params[:access_types] || [params[:access_type]].flatten.compact
      @access_methods = params[:access_methods] || [params[:access_method]].flatten.compact
      @metric_types = params[:metric_types] || [params[:metric_type]].flatten.compact
      @attributes_to_show = params[:attributes_to_show] || []
      @include_parent_details = params[:include_parent_details] || false
      @include_component_details = params[:include_component_details] || false
      # Crazy Counter 5 Report Master Report Form Logic
      if params[:exclude_monthly_details].present?
        @include_monthly_details = params[:include_monthly_details].present?
        @exclude_monthly_details = !@include_monthly_details
      else
        @exclude_monthly_details = false
        @include_monthly_details = true
      end
      @errors = []

      set_platforms

      case @report_type
      when 'pr_p1'
        @metric_types = %w[Searches_Platform Total_Item_Requests Unique_Item_Requests Unique_Title_Requests]
        @data_types = %w[Book]
        @access_types = %w[Controlled]
        @access_methods = %w[Regular]
      when 'tr_b1'
        @metric_types = %w[Total_Item_Requests Unique_Title_Requests]
        @data_types = %w[Book]
        @access_types = %w[Controlled]
        @access_methods = %w[Regular]
      when 'tr_b2'
        @metric_types = %w[No_License]
        @data_types = %w[Book]
        @access_types = %w[Controlled]
        @access_methods = %w[Regular]
      when 'tr_b3'
        @metric_types = %w[Total_Item_Investigations Unique_Item_Investigations Unique_Title_Investigations
                           Total_Item_Requests Unique_Item_Requests Unique_Title_Requests]
        @data_types = %w[Book]
        @access_types = %w[Controlled OA_Gold]
        @access_methods = %w[Regular]
        @attributes_to_show = %w[Access_Type]
      when 'ir_m1'
        @metric_types = %w[Total_Item_Requests]
        @data_types = %w[Multimedia]
        @access_types = %w[OA_Gold Controlled]
        @access_methods = %w[Regular]
      when 'counter4_br2'
        # Ideally this is very temporary
        # COUNTER4 doesn't have metric types, but according to the COUNTER 5 spec this is:
        # "R5 equivalent:  Total_Item_Requests AND Data_Type=Book AND Section_Type=Chapter|Section"
        # So... sort of a Total_Item_Requests. We'll use that to get past validation but it's actually
        # custom
        @metric_types = %w[Total_Item_Requests]
        @access_types = %w[Controlled]
      end

      @report_title = CounterReport::COUNTER_REPORT_TITLE[@report_type.to_sym]
    end

    def validate!
      report_type? &&
        institution? &&
        press? &&
        allowed_data_types? &&
        allowed_section_types? &&
        yop_valid? &&
        allowed_access_types? &&
        allowed_access_methods? &&
        allowed_metric_types?
    end

    def report_type?
      @errors << "Report type '#{report_type}' is not valid" unless CounterReport::SUPPORTED_COUNTER_REPORT_TYPES.include?(@report_type)
      return false if @errors.present?

      true
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

    def yop_valid?
      return true if @yop.blank?

      # All years (default), a specific year in the format yyyy,
      # or a range of years in the format yyyy-yyyy.
      # Use 0001 for unknown or 9999 for articles in press.
      @errors << "YOP: Invalid format. All years (default), a specific year in the format yyyy, or a range of years in the format yyyy-yyyy. Use 0001 for unknown or 9999 for articles in press." unless /\s*\A(\d{4}|\d{4}-\d{4})\z\s*/.match?(@yop)
      return false if @errors.present?

      true
    end

    def yop_values
      match = /\s*\A(\d{4})-(\d{4})\z\s*/.match(@yop)
      return [match[1], match[2]] if match.present?

      match = /\s*\A(\d{4})\z\s*/.match(@yop)
      return [match[0]] if match.present?

      []
    end

    # ir ir_m1 pr pr_p1 tr tr_b1 tr_b2 tr_b3 counter4_br2
    def allowed_data_types
      case @report_type
      when 'pr', 'pr_p1'
        # %w[Book Book_Segment Multimedia Other]
        %w[Book]
      when 'tr'
        # %w[Journal Book]
        %w[Book]
      when 'tr_b1', 'tr_b2', 'tr_b3'
        %w[Book]
      when 'tr_j1', 'tr_j2', 'tr_j3', 'tr_j4'
        # %w[Journal]
        %w[]
      when 'ir'
        # %w[Article Book Book_Segment Multimedia Other]
        %w[Book Multimedia]
      when 'ir_a1'
        # %w[Article]
        %w[]
      when 'ir_m1'
        %w[Multimedia]
      when 'counter4_br2'
        # %w[Article Book Book_Segment Multimedia Other]
        %w[Book Multimedia]
      else
        %w[]
      end
    end

    def allowed_data_types?
      allowed_values?('Data Type', @data_types, allowed_data_types)
    end

    def allowed_section_types
      case @report_type
      when 'tr', 'tr_b1', 'tr_b2', 'tr_b3', 'tr_j1', 'tr_j2', 'tr_j3', 'tr_j4'
        # %w[Book Chapter Section]
        %w[Book]
      else
        %w[]
      end
    end

    def allowed_section_types?
      allowed_values?('Section Type', @section_types, allowed_section_types)
    end

    def allowed_access_types
      case @report_type
      when 'pr', 'pr_p1'
        # %w[Controlled OA_Gold Other_Free_To_Read]
        %w[Controlled OA_Gold]
      when 'tr', 'tr_b2', 'tr_b3', 'tr_j2', 'tr_j3'
        %w[Controlled OA_Gold]
      when 'tr_b1', 'tr_j1', 'tr_j4'
        %w[Controlled]
      when 'ir', 'ir_m1'
        # %w[Controlled OA_Gold Other_Free_To_Read]
        %w[Controlled OA_Gold]
      when 'counter4_br2'
        # %w[Controlled OA_Gold Other_Free_To_Read]
        %w[Controlled OA_Gold]
      else
        %w[]
      end
    end

    def allowed_access_types?
      allowed_values?('Access Type', @access_types, allowed_access_types)
    end

    def allowed_access_methods
      case @report_type
      when 'pr', 'tr', 'ir'
        # %w[Regular TDM]
        %w[Regular]
      else
        %w[Regular]
      end
    end

    def allowed_access_methods?
      allowed_values?('Access Method', @access_methods, allowed_access_methods)
    end

    def allowed_metric_types
      case @report_type
      when 'pr'
        %w[Searches_Platform
           Total_Item_Investigations Total_Item_Requests
           Unique_Item_Investigations Unique_Item_Requests
           Unique_Title_Investigations Unique_Title_Requests]
      when 'pr_p1'
        %w[Searches_Platform Total_Item_Requests
           Unique_Item_Requests Unique_Title_Requests]
      when 'tr'
        %w[Total_Item_Investigations Total_Item_Requests
           Unique_Item_Investigations Unique_Item_Requests
           Unique_Title_Investigations Unique_Title_Requests
           Limit_Exceeded No_License]
      when 'tr_b1'
        %w[Total_Item_Requests Unique_Title_Requests]
      when 'tr_b2'
        %w[Limit_Exceeded No_License]
      when 'tr_b3'
        %w[Total_Item_Investigations Total_Item_Requests
           Unique_Item_Investigations Unique_Item_Requests
           Unique_Title_Investigations Unique_Title_Requests]
      when 'jr_1', 'jr_4'
        %w[Total_Item_Requests Unique_Item_Requests]
      when  'jr_2'
        %w[Limit_Exceeded No_License]
      when 'jr_3'
        %w[Total_Item_Investigations Total_Item_Requests
           Unique_Item_Investigations Unique_Item_Requests]
      when 'ir'
        %w[Total_Item_Investigations Total_Item_Requests
           Unique_Item_Investigations Unique_Item_Requests
           Limit_Exceeded No_License]
      when 'ir_a1'
        %w[Total_Item_Requests Unique_Item_Requests]
      when 'ir_m1'
        %w[Total_Item_Requests]
      when 'counter4_br2'
        %w[Searches_Platform
           Total_Item_Investigations Total_Item_Requests
           Unique_Item_Investigations Unique_Item_Requests
           Unique_Title_Investigations Unique_Title_Request
           Limit_Exceeded No_License]
      else
        %w[]
      end
    end

    def allowed_metric_types?
      allowed_values?('Metric Type', @metric_types, allowed_metric_types)
    end

    private

      def allowed_values?(label, values, allowed_values)
        return true if values.blank? && @counter_5_report

        values.each do |value|
          unless allowed_values.include?(value)
            @errors << "#{label}: '#{value}' is not allowed"
          end
        end
        return false if @errors.present?

        true
      end

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
  end
end
