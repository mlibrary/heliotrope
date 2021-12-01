# frozen_string_literal: true

# HELIO-4115 - this is no longer used but is left in place as inspiration for the next solution

class StatsGraphService
  attr_accessor :pageviews

  def initialize(ids, date_uploaded)
    @ids = Array(ids)
    @date_uploaded = date_uploaded.strftime('%Q').to_i
  end

  def pageviews_over_time_graph_data
    [{ "label": "Total Pageviews", "data": flot_pageviews_over_time.to_a.sort }].to_json
  end

  private

    def timestamped_pageviews_by_ids
      # we want the output here to be structured for Flot as used in Hyrax, with unixtimes in milliseconds
      data = {}
      count = 0
      GoogleAnalyticsHistory.where(noid: @ids).each do |r|
        timestamp = Date.strptime(r.original_date, '%Y%m%d').strftime('%Q').to_i
        # skip if the pageview was before date_uploaded. Could be a reused NOID, for example.
        next unless timestamp >= @date_uploaded

        if data[timestamp].present?
          data[timestamp] += r.pageviews
        else
          data[timestamp] = r.pageviews
        end
        count += r.pageviews
      end

      if count.zero?
        @pageviews = 0
        return {}
      end

      @pageviews ||= count
      data # essentially a hash with 12am timestamp keys and pageview values for that day
    end

    def flot_pageviews_over_time
      data = timestamped_pageviews_by_ids
      return [] if data.blank?
      data = data.to_a.sort

      # ensure that the graph starts from date_uploaded
      start_timestamp = @date_uploaded
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
