# frozen_string_literal: true

require 'zlib'

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

    tmp = Tempfile.new
    # gzip is easiest here. We could use zip if users want it I guess,
    # but it's a little more complicated.
    # Either way some kind of compression will be required since uncompressed
    # reports can get over 50MB pretty easily.
    Zlib::GzipWriter.open(tmp) do |fo|
      fo.write CounterReporterService.csv(report)
    end
    tmp.close

    institution = if args[:institution] == "*"
                    "All Institutions"
                  else
                    Greensub::Institution.where(identifier: args[:institution]).first&.name
                  end
    press = Press.find(args[:press]).name
    start_date = args[:start_date]
    end_date = args[:end_date]

    email_subject = "Fulcrum COUNTER 5 report #{report_type.upcase} for \"#{institution}\" of the Press \"#{press}\" from #{start_date} to #{end_date}"

    params = {}
    params[:email] = email
    params[:email_subject] = email_subject
    params[:csv_file] = tmp
    params[:press] = press
    params[:institution] = institution
    params[:report_type] = report_type.upcase
    params[:start_date] = start_date
    params[:end_date] = end_date

    CounterReportMailer.send_report(params).deliver_now
    Rails.logger.info("[COUNTER REPORT] emailed #{report_type.upcase} to #{params[:email]}")
  end
end
