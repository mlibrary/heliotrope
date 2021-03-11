# frozen_string_literal: true

require 'zip'

class EmailCounterReportJob < ApplicationJob
  queue_as :counter_report

  def perform(email:, report_type:, args:) # rubocop:disable Metrics/CyclomaticComplexity
    report = case report_type
             when "pr"
               CounterReporterService.pr(args)
             when "pr_p1"
               CounterReporterService.pr_p1(args)
             when "tr"
               CounterReporterService.tr(args)
             when "tr_b1"
               CounterReporterService.tr_b1(args)
             when "tr_b2"
               CounterReporterService.tr_b2(args)
             when "tr_b3"
               CounterReporterService.tr_b3(args)
             when "ir"
               CounterReporterService.ir(args)
             when "ir_m1"
               CounterReporterService.ir_m1(args)
             when "counter4_br2"
               CounterReporterService.counter4_br2(args)
             end

    institution = if args[:institution] == "*"
                    "All Institutions"
                  else
                    Greensub::Institution.where(identifier: args[:institution]).first&.name
                  end
    press = Press.find(args[:press]).name
    start_date = args[:start_date]
    end_date = args[:end_date]

    email_subject = "Fulcrum #{report_type.upcase} \"#{institution}\" \"#{press}\" #{start_date} to #{end_date}"

    params = {}
    params[:email] = email
    params[:email_subject] = email_subject
    params[:zip_file] = build_zip(report_type, email_subject, report)
    params[:press] = press
    params[:institution] = institution
    params[:report_type] = report_type.upcase
    params[:start_date] = start_date
    params[:end_date] = end_date

    CounterReportMailer.send_report(params).deliver_now
    Rails.logger.info("[COUNTER REPORT] emailed #{report_type.upcase} to #{params[:email]}")
  end

  def build_zip(report_type, email_subject, report)
    tmp_zip = Tempfile.new('counter_email_zip')
    tmp_report = Tempfile.new('counter_email_report')

    if report_type == "counter4_br2"
      # HELIO-3703 counter4_br2 reports are weird
      tmp_report.write(report)
    else
      tmp_report.write(CounterReporterService.csv(report))
    end
    tmp_report.close

    report_name = email_subject.gsub(/[^0-9A-z.\-]/, '_') + ".csv"

    Zip::OutputStream.open(tmp_zip) { |zos| }
    Zip::File.open(tmp_zip.path, Zip::File::CREATE) do |zip|
      zip.add(report_name, tmp_report.path)
    end

    tmp_zip.close
    tmp_report.unlink
    tmp_zip
  end
end
