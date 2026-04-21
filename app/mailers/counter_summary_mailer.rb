# frozen_string_literal: true

class CounterSummaryMailer < ApplicationMailer
  default from: "fulcrum-dev@umich.edu"
  default to: "fulcrum-dev@umich.edu"

  def missing_file(year, month)
    @year = year
    @month = month
    @month_name = Date::MONTHNAMES[month]
    @expected_filename = "fulcrum_metric_totals-#{year}-#{format('%02d', month)}.csv"
    @check_date = Time.zone.now.strftime("%Y-%m-%d %H:%M:%S %Z")

    mail(subject: "Missing SIQ Counter Statistics File for #{@month_name} #{year}")
  end
end
