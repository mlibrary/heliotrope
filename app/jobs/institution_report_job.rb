# frozen_string_literal: true

require 'csv'

class InstitutionReportJob < ApplicationJob
  def perform(args:)
    report_name = if args[:report_type] == "request"
                    "Total_Item_Requests"
                  else
                    "Total_Item_Investigations"
                  end

    press = Press.find args[:press]
    start_date = args[:start_date]
    end_date = args[:end_date]
    report_heading = "#{report_name} for all Institutions #{press.name} #{start_date} to #{end_date}"

    results = InstitutionReportService.run(args: args)
    output = InstitutionReportService.make_csv(subject: report_heading, results: results)

    tmp = Tempfile.new
    tmp.write(output)
    tmp.close

    params = {}
    params[:email] = args[:email]
    params[:report_heading] = report_heading
    params[:csv_file] = tmp
    params[:press] = press.name
    params[:report_name] = report_name
    params[:start_date] = start_date
    params[:end_date] = end_date

    ReportMailer.send_report(params).deliver_now
    Rails.logger.info("[INSTITUTION REPORT] emailed #{report_name} to #{args[:email]}")
  end
end
