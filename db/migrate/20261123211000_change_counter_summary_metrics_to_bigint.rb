# frozen_string_literal: true

class ChangeCounterSummaryMetricsToBigint < ActiveRecord::Migration[6.1]
  METRIC_COLUMNS = %i[
    total_item_requests_month
    total_item_investigations_month
    unique_item_requests_month
    unique_item_investigations_month
    total_item_requests_life
    total_item_investigations_life
    unique_item_requests_life
    unique_item_investigations_life
  ].freeze

  def up
    METRIC_COLUMNS.each do |column|
      change_column :counter_summaries, column, :bigint, default: 0, null: false
    end
  end

  def down
    METRIC_COLUMNS.each do |column|
      change_column :counter_summaries, column, :integer, default: 0, null: false
    end
  end
end
