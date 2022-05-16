# frozen_string_literal: true

class FixityMailer < ApplicationMailer
  default from: "fulcrum-dev@umich.edu"
  default to: "fulcrum-dev@umich.edu"
  default subject: "Fulcrum Fixity Failure(s)"

  def send_failures(failures)
    @today = Time.zone.now.strftime "%Y-%m-%d"
    @failures = failures
    if Settings.host == "www.fulcrum.org"
      mail
    else
      mail(to: "sethajoh@umich.edu")
    end
  end
end
