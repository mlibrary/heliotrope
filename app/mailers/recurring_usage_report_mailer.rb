# frozen_string_literal: true

class RecurringUsageReportMailer < ApplicationMailer
  default from: "fulcrum-info@umich.edu"

  def send_report(to, start_date, end_date, zipfile)
    @email_subject = "Weekly Fulcrum Reports for BAR"
    @start_date = start_date
    @end_date = end_date
    attachment_name = "Weekly_Fulcrum_Reports_#{Time.zone.now.strftime("%Y-%m-%d")}.zip"
    attachments[attachment_name] = File.read(zipfile)
    mail(to: to, subject: @email_subject)

    File.unlink(zipfile)
  end
end
