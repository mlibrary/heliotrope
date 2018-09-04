# frozen_string_literal: true

class CounterReportsController < ApplicationController
  before_action :set_counter_report_service, only: %i[index]
  before_action :set_counter_report, only: %i[show form]
  before_action :set_report_header, only: %i[show form]

  COUNTER_REPORT_TITLE = {
    cr: 'Custom Report',
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

  # GET /counter_reports
  def index; end

  # GET /counter_reports/new
  def new; end

  # GET/POST /counter_reports/:id/form
  def form
    if request.post? # rubocop:disable Style/GuardClause
      respond_to do |format|
        if @report_header.update(report_header_params)
          format.html { redirect_to @counter_report, notice: 'COUNTER Report was successfully created.' }
          # format.json { render :show, status: :ok, location: @counter_report }
        end
      end
    end
  end

  # POST /counter_reports/:id
  def show
    buffer = +''
    CSV.generate(buffer) do |csv|
      csv << ['Label', 'Value', 'Comment']
      csv << ['Report_Name', @title, 'Name of the report']
      csv << ['Report_ID', @id.to_s.upcase, 'Identifier of the report']
      csv << ['Release', '5', 'Version']
      csv << ['Institution_Name', 'Kostin', 'Name of the institution usage is attributed to']
      csv << ['Institution_ID', 'Kostin', 'Identifier(s) for the institution usage is attributed to']
      csv << ['Metric_Types', 'Kostin', 'Semicolon-space delimited list of metric types included in the report']
      csv << ['Report_Filters', 'Kostin', 'Semicolon-space delimited list of filters applied to the data to generate the report']
      csv << ['Report_Attributes', 'Kostin', 'Semicolon-space delimited list of attributes applied to the data to generate the report']
      csv << ['Exceptions', 'Kostin', 'Any exceptions that occurred in generating the report']
      csv << ['Reporting_Period', 'Kostin', 'Date range covered by the report']
      csv << ['Created', 'Kostin', 'Date the report was run']
      csv << ['Created_By', 'Kostin', 'Name of organization or system that generated the report']
      csv << ['<row left blank>', '', '']
    end
    @header = CSV.parse(buffer, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

    buffer = +''
    CSV.generate(buffer) do |csv|
      headers = []
      row1 = []
      row2 = []
      (COUNTER_REPORT_HEADERS[@id] || ['Header']).each_with_index do |column, index|
        headers << column
        row1 << index
        row2 << index * index
      end
      csv << headers << row1 << row2
    end
    @report = CSV.parse(buffer, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_counter_report_service
      @counter_report_service = CounterReportService.new(params[:customer_id], current_user.id)
    end

    def set_counter_report
      @counter_report = params[:id]&.downcase&.to_sym
      @counter_report = :cr unless COUNTER_REPORT_TITLE[@counter_report]
      @title = COUNTER_REPORT_TITLE[@counter_report]
    end

    def set_report_header
      @report_header = SwaggerClient::SUSHIReportHeader.new
      @report_header.created = 'Today'
      @report_header.created_by = 'Fulcrum.org'
      # @report_header.Customer_ID = ''
      @report_header.report_id = @counter_report.to_s.upcase
      @report_header.release = '5'
      @report_header.report_name = @title
      # @report_header.Institution_Name = ''
      @report_header.institution_id = []
      @report_header.report_filters = []
      @report_header.report_attributes = []
      @report_header.exceptions = []
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def counter_report_params
      params.require(:counter_report).permit
    end

    def report_header_params
      params.require(:sushi_report_header).permit(:customer_id, :report_filters, :report_attributes)
    end
end
