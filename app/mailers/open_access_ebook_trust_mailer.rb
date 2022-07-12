# frozen_string_literal: true

class OpenAccessEbookTrustMailer < ApplicationMailer
  default from: "fulcrum-info@umich.edu"

  def send_report(zipfile)
    @month_year = Time.zone.now.prev_month.strftime("%B %Y")
    @email_subject = "Monthly Fulcrum reports for OAeBU Data Trust"
    attachment_name = "Monthly Fulcrum_Reports #{@month_year}.zip".tr(" ", "_")
    attachments[attachment_name] = File.read(zipfile)
    mail(to: Settings.open_access_ebook_trust_emails.to, cc: Settings.open_access_ebook_trust_emails.cc, subject: @email_subject)

    File.unlink(zipfile)
  end
end
