# frozen_string_literal: true

class CounterReportsController < ApplicationController
  before_action :set_counter_report_service, only: %i[index show edit update]
  before_action :set_counter_report, only: %i[show update]
  before_action :set_presses_and_institutions, only: %i[index show]

  COUNTER_REPORT_TITLE = {
    pr: 'Platform Master Report',
    pr_p1: 'Platform Usage',
    dr: 'Database Master Report',
    dr_d1: 'Database Search and Item Usage',
    dr_d2: 'Database Access Denied',
    tr: 'Title Master Report',
    tr_b1: 'Book Requests (Excluding OA_Gold)',
    tr_b2: 'Access Denied by Book',
    tr_b3: 'Book Usage by Access Type',
    tr_j1: 'Journal Requests (Excluding OA_Gold)',
    tr_j2: 'Access Denied by Journal',
    tr_j3: 'Journal Usage by Access Type',
    tr_j4: 'Journal Requests by YOP (Excluding OA_Gold)',
    ir: 'Item Master Report',
    ir_a1: 'Journal Article Requests',
    ir_m1: 'Multimedia Item Requests'
  }.freeze

  def index
    return render if params[:customer_id].present?
    render 'counter_reports/without_customer_id/index'
  end

  def edit
    @customer_id = params[:customer_id]
    @id = params[:id]
  end

  def update
    respond_to do |format|
      format.html { redirect_to customer_counter_report_path(params[:customer_id], params[:id]), notice: 'COUNTER Report was successfully created.' }
    end
  end

  def show # rubocop:disable Metrics/CyclomaticComplexity
    return render if params[:customer_id].present?
    # institutional 'guest' users can only see their institutions
    # press admins can only see their presses
    return render 'hyrax/base/unauthorized', status: :unauthorized unless authorized_insitutions_or_presses?

    case params[:id]
    when 'pr_p1'
      @report = CounterReporterService.pr_p1(params)
    when 'tr_b1'
      @report = CounterReporterService.tr_b1(params)
    when 'tr'
      @report = CounterReporterService.tr(params)
    end

    if params[:csv]
      send_data CounterReporterService.csv(@report), filename: "Fulcrum_#{@title.gsub(/\s/, '_')}_#{Time.zone.today.strftime('%Y-%m-%d')}.csv"
    else
      render 'counter_reports/without_customer_id/show'
    end
  end

  private

    def authorized_insitutions_or_presses?
      return false unless @institutions.map(&:identifier).include?(params[:institution])
      return false if @presses.present? && !@presses.map(&:id).include?(params[:press].to_i)
      true
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_counter_report_service
      @counter_report_service = CounterReportService.new(params[:customer_id], current_user.id) if params[:customer_id].present?
    end

    def set_counter_report
      @title = COUNTER_REPORT_TITLE[params[:id]&.downcase&.to_sym]
      @counter_report = @counter_report_service.report(params[:id]) if params[:customer_id].present?
    end

    def set_presses_and_institutions
      @presses = current_user&.admin_presses || []
      @institutions = if @presses.present?
                        Institution.all # over 1000 of these in production = fun
                      else
                        current_institutions
                      end
      return render 'hyrax/base/unauthorized', status: :unauthorized if params[:customer_id].nil? && @institutions.empty?
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def counter_report_params
      params.require(:counter_report).permit
      params.permit(:institution, :press, :start_date, :end_date, :metric_type, :access_type, :access_method, :data_type, :yop)
    end
end
