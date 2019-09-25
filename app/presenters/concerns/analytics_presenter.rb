# frozen_string_literal: true

module AnalyticsPresenter
  extend ActiveSupport::Concern

  attr_accessor :pageviews

  def ids_array(ids)
    ids.is_a?(Array) ? ids : [ids]
  end

  def timestamped_pageviews_by_ids(ids)
    # we want the output here to be structured for Flot as used in Hyrax, with unixtimes in milliseconds
    ids = ids_array(ids)
    data = {}
    count = 0
    GoogleAnalyticsHistory.where(noid: ids).each do |r|
      timestamp = Date.strptime(r.original_date, '%Y%m%d').strftime('%Q').to_i
      data[timestamp] = r.pageviews
      count += r.pageviews
    end

    if count.zero?
      @pageviews = 0
      return {}
    end

    @pageviews ||= count
    data # essentially a hash with 12am timestamp keys and pageview values for that day
  end

  def flot_pageviews_over_time(ids)
    data = timestamped_pageviews_by_ids(ids)
    return [] if data.blank?
    data = data.to_a.sort

    # ensure that the graph starts from date_uploaded
    start_timestamp = date_uploaded.strftime('%Q').to_i
    data.unshift([start_timestamp, 0]) if data[0][0] > start_timestamp

    # note that with `config.time_zone` not set, Date.yesterday is relative to UTC time, which is OK here
    end_timestamp = Date.yesterday.strftime('%Q').to_i
    # if there's been no activity in 30 days or more, add a final point to the graph
    data.push([end_timestamp, 0]) if end_timestamp - data.last[0] >= 2_592_000_000

    # we want the values for a given day to be a running tally
    (1..data.count - 1).each do |i|
      data[i][1] += data[i - 1][1]
    end
    data
  end
end
