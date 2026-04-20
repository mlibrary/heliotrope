# frozen_string_literal: true

class CounterSummary < ApplicationRecord
  validates :press_id, presence: true
  validates :year, presence: true
  validates :month, presence: true

  scope :for_press, ->(press_id) { where(press_id: press_id) }
  scope :for_year, ->(year) { where(year: year) }
  scope :for_month, ->(month) { where(month: month) }
end
