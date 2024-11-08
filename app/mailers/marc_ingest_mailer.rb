# frozen_string_literal: true

class MarcIngestMailer < ApplicationMailer
  default from: "fulcrum-dev@umich.edu"
  default to: "sethajoh@umich.edu"
  default subject: "MARC Ingest Report"

  def send_mail(report)
    @today = Time.zone.now.strftime "%Y-%m-%d"
    @report = report

    mail(to: "sethajoh@umich.edu")
  end
end
