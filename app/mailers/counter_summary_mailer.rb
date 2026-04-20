# frozen_string_literal: true

class CounterSummaryMailer < ApplicationMailer
  default from: "fulcrum-info@umich.edu"

  def send_report(args)
    @email = args[:email]
    @subject = args[:subject]
    @press = args[:press]
    @month = args[:month]
    @year = args[:year]

    mail(to: @email, subject: @subject)
  end
end
