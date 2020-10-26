# frozen_string_literal: true

class CounterReportMailer < ApplicationMailer
  default from: "fulcrum-info@umich.edu"

  def send_report(args)
    email = args[:email]
    zip_file = args[:zip_file]
    @email_subject = args[:email_subject]
    @press = args[:press]
    @institution = args[:institution]
    @report_type = args[:report_type]
    @start_date = args[:start_date]
    @end_date = args[:end_date]

    attachment_name = @email_subject.gsub(/[^0-9A-z.\-]/, '_') + ".zip"
    attachments[attachment_name] = File.read(zip_file)
    mail(to: email, subject: @email_subject)

    zip_file.unlink
  end
end
