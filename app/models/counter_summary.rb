# frozen_string_literal: true

class CounterSummary < ApplicationRecord
  validates :monograph_noid, presence: true
  validates :month, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 2000 }
  validates :monograph_noid, uniqueness: { scope: [:month, :year], message: "already has statistics for this month and year" }

  validates :total_item_requests_month, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_item_investigations_month, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unique_item_requests_month, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unique_item_investigations_month, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_item_requests_life, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_item_investigations_life, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unique_item_requests_life, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unique_item_investigations_life, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Logical validation: lifetime metrics should be >= monthly metrics
  validate :lifetime_metrics_greater_than_or_equal_to_monthly

  scope :for_monograph, ->(noid) { where(monograph_noid: noid) }
  scope :for_year, ->(year) { where(year: year) }
  scope :for_month, ->(month) { where(month: month) }
  scope :for_period, ->(year, month) { where(year: year, month: month) }
  scope :recent_months, ->(count = 6) { order(year: :desc, month: :desc).limit(count) }
  scope :older_than, ->(date) { where("year < ? OR (year = ? AND month < ?)", date.year, date.year, date.month) }

  # Get statistics for display with last N months
  # Returns an array of CounterSummary records ordered from oldest to newest
  def self.for_display(noid, months_count = 6)
    for_monograph(noid)
      .order(year: :desc, month: :desc)
      .limit(months_count)
      .reverse
  end

  # Clean up statistics older than the specified number of months
  def self.cleanup_old_stats(months_to_keep = 24)
    cutoff_date = Time.zone.today.months_ago(months_to_keep)
    older_than(cutoff_date).delete_all
  end

  # Check if statistics exist for a given period
  def self.exists_for_period?(year, month)
    exists?(year: year, month: month)
  end

  def month_year_string
    Date.new(year, month, 1).strftime("%b-%Y")
  end

  private

    def lifetime_metrics_greater_than_or_equal_to_monthly
      if !total_item_requests_life.nil? && !total_item_requests_month.nil? &&
         total_item_requests_life < total_item_requests_month
        errors.add(:total_item_requests_life, "must be greater than or equal to monthly requests")
      end

      if !total_item_investigations_life.nil? && !total_item_investigations_month.nil? &&
         total_item_investigations_life < total_item_investigations_month
        errors.add(:total_item_investigations_life, "must be greater than or equal to monthly investigations")
      end

      if !unique_item_requests_life.nil? && !unique_item_requests_month.nil? &&
         unique_item_requests_life < unique_item_requests_month
        errors.add(:unique_item_requests_life, "must be greater than or equal to monthly unique requests")
      end

      if !unique_item_investigations_life.nil? && !unique_item_investigations_month.nil? &&
         unique_item_investigations_life < unique_item_investigations_month
        errors.add(:unique_item_investigations_life, "must be greater than or equal to monthly unique investigations")
      end
    end
end
