# frozen_string_literal: true

class MonthlyCounterStatsJob < ApplicationJob
  queue_as :counter_report

  def perform(press_id:, year:, month:, email:)
    press = Press.find(press_id)
    Rails.logger.info("[MONTHLY COUNTER STATS] Processing stats for #{press.name} #{year}-#{month}")

    CounterSummaryMailer.send_report(
      email: email,
      subject: "Monthly Counter Stats for #{press.name} #{year}-#{month}",
      press: press.name,
      month: month,
      year: year
    ).deliver_now
  end
end
