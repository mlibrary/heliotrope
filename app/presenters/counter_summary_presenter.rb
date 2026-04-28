# frozen_string_literal: true

class CounterSummaryPresenter
  attr_reader :monograph_noid

  def initialize(monograph_noid)
    @monograph_noid = monograph_noid
  end

  # Get 6 months of statistics for display
  # Returns array of CounterSummary records, oldest to newest
  def statistics
    @statistics ||= CounterSummary.for_display(monograph_noid, 6)
  end

  # Check if there are any statistics to display
  def any_statistics?
    statistics.present?
  end

  # Get the most recent statistic record (for life totals)
  def most_recent
    statistics.last
  end

  # Get formatted month headers for the table (e.g., "Sep-2025")
  def month_headers
    statistics.map(&:month_year_string)
  end

  # Get monthly data for a specific metric type
  # Returns array of values for each month
  def monthly_data_for(metric_type)
    statistics.map { |stat| stat.public_send(metric_type) }
  end

  # Get life total for a metric (from most recent month only)
  def life_total_for(metric_type)
    most_recent&.public_send(metric_type) || 0
  end

  # Metric type display names
  METRIC_TYPES = {
    'Total_Item_Investigations' => 'total_item_investigations_month',
    'Total_Item_Requests' => 'total_item_requests_month',
    'Unique_Item_Investigations' => 'unique_item_investigations_month',
    'Unique_Item_Requests' => 'unique_item_requests_month'
  }.freeze

  LIFE_METRIC_TYPES = {
    'Total_Item_Investigations' => 'total_item_investigations_life',
    'Total_Item_Requests' => 'total_item_requests_life',
    'Unique_Item_Investigations' => 'unique_item_investigations_life',
    'Unique_Item_Requests' => 'unique_item_requests_life'
  }.freeze

  # Get all metric type names in display order
  def metric_type_names
    METRIC_TYPES.keys
  end

  # Get monthly column name for a metric type
  def monthly_column_for(metric_name)
    METRIC_TYPES[metric_name]
  end

  # Get life column name for a metric type
  def life_column_for(metric_name)
    LIFE_METRIC_TYPES[metric_name]
  end
end
