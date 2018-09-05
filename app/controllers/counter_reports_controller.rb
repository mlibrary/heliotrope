# frozen_string_literal: true

class CounterReportsController < ApplicationController
  before_action :set_counter_report_service, only: %i[index show edit update]
  before_action :set_counter_report, only: %i[show update]

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

  # GET /customers/:customer_id/counter_reports
  def index; end

  # GET /customers/:customer_id/counter_reports/:id/edit
  def edit
    @customer_id = params[:customer_id]
    @id = params[:id]
  end

  # PUT/PATCH /customers/:customer_id/counter_reports/:id
  def update
    respond_to do |format|
      format.html { redirect_to customer_counter_report_path(params[:customer_id], params[:id]), notice: 'COUNTER Report was successfully created.' }
      # format.json { render :show, status: :ok, location: @counter_report }
    end
  end

  # GET /customers/:customer_id/counter_reports/:id
  def show; end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_counter_report_service
      @counter_report_service = CounterReportService.new(params[:customer_id], current_user.id)
    end

    def set_counter_report
      @title = COUNTER_REPORT_TITLE[params[:id]&.downcase&.to_sym]
      @counter_report = @counter_report_service.report(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def counter_report_params
      params.require(:counter_report).permit
    end
end
