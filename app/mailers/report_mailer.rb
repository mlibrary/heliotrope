# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  default from: "fulcrum-info@umich.edu"

  def send_report(args)
    email = args[:email]
    report_heading = args[:report_heading]
    csv_file = args[:csv_file]
    @press = args[:press]
    @report_name = args[:report_name]
    @start_date = args[:start_date]
    @end_date = args[:end_date]

    attachment_name = report_heading.gsub(/[^0-9A-z.\-]/, '_') + ".csv"
    attachments[attachment_name] = File.read(csv_file)
    mail(to: email, subject: report_heading)

    csv_file.unlink
  end
end
