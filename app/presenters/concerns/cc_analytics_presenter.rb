# frozen_string_literal: true

module CCAnalyticsPresenter
  extend ActiveSupport::Concern

  attr_accessor :pageviews

  def ids_array(ids)
    ids.is_a?(Array) ? ids : [ids]
  end

  def pageviews_by_path(path)
    start_time = date_uploaded.strftime('%Q').to_i
    count = 0
    pageviews = Rails.cache.read('ga_pageviews')
    return '?' if pageviews.nil?
    if pageviews.is_a?(Array)
      pageviews.each do |entry|
        timestamp = DateTime.strptime(entry[:date], '%Y%m%d').strftime('%Q').to_i
        # block pageviews older than date_uploaded, likely from reused NOID
        next unless timestamp >= start_time
        count += entry[:pageviews].to_i if entry[:pagePath] == path
      end
    end
    count
  end

  def pageviews_by_ids(ids)
    ids = ids_array(ids)
    start_time = date_uploaded.strftime('%Q').to_i
    count = 0
    pageviews = Rails.cache.read('ga_pageviews')
    return '?' if pageviews.nil?
    if pageviews.is_a?(Array)
      pageviews.each do |entry|
        timestamp = DateTime.strptime(entry[:date], '%Y%m%d').strftime('%Q').to_i
        # block pageviews older than date_uploaded, likely from reused NOID
        next unless timestamp >= start_time
        ids.each do |id|
          count += entry[:pageviews].to_i if entry[:pagePath].include? id
        end
      end
    end
    count
  end

  def timestamped_pageviews_by_ids(ids)
    # we want the output here to be structured for Flot as used in Hyrax, with unixtimes in milliseconds
    ids = ids_array(ids)
    start_time = date_uploaded.strftime('%Q').to_i
    pageviews = Rails.cache.read('ga_pageviews')
    if pageviews.nil?
      @pageviews ||= '?'
      return {}
    end

    data = {}
    # as this stuff looks expensive, going to do a count here as well and memoize it
    count = 0
    if pageviews.is_a?(Array)
      pageviews.each do |entry|
        timestamp = DateTime.strptime(entry[:date], '%Y%m%d').strftime('%Q').to_i
        # block pageviews older than date_uploaded, likely from reused NOID
        next unless timestamp >= start_time
        ids.each do |id|
          next unless entry[:pagePath].include? id
          views = entry[:pageviews].to_i
          data[timestamp] = data[timestamp].blank? ? views : data[timestamp] + views
          count += views
        end
      end
    end
    @pageviews ||= count
    data # essentially a hash with 12am timestamp keys and pageview values for that day
  end

  def flot_daily_pageviews_zero_pad(ids)
    data = timestamped_pageviews_by_ids(ids)
    return [] if data.blank?
    start_timestamp = date_uploaded.strftime('%Q').to_i
    # ensure that the graph ends yesterday (I don't think today can be in the cronjob-created cache anyway)
    end_timestamp = DateTime.yesterday.strftime('%Q').to_i

    # zero-pad data to fill in days with no page views
    i = start_timestamp
    while i <= end_timestamp
      data[i] = 0 if data[i].blank?
      i += 86_400_000 # 1 day in milliseconds
    end
    data.to_a.sort
  end

  def flot_pageviews_over_time(ids)
    data = timestamped_pageviews_by_ids(ids)
    return [] if data.blank?
    data = data.to_a.sort

    # ensure that the graph starts from date_uploaded
    start_timestamp = date_uploaded.strftime('%Q').to_i
    data.unshift([start_timestamp, 0]) if data[0][0] > start_timestamp

    end_timestamp = DateTime.yesterday.strftime('%Q').to_i
    # if there's been no activity in 30 days or more, add a final point to the graph
    data.push([end_timestamp, 0]) if end_timestamp - data.last[0] >= 2_592_000_000

    # we want the values for a given day to be a running tally
    (1..data.count - 1).each do |i|
      data[i][1] += data[i - 1][1]
    end
    data
  end
end
