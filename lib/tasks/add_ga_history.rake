# frozen_string_literal: true

desc "save google analytics data"
namespace :heliotrope do
  task :add_ga_history, [:start_date, :end_date] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:add_ga_history[2018-01-01, 2018-03-31]"

    # Or: don't supply dates and just get yesterday's data
    start_date = args.start_date || Date.yesterday
    end_date = args.end_date || Date.yesterday

    # You can run this over and over on old data without adding duplicates to the table
    # because of a uniqueness validation in the model

    ga_id = Rails.application.secrets.google_analytics_id
    if ga_id.present?
      begin
        profile = AnalyticsService.profile(ga_id)
        if profile.present?
          total_results = Pageview.results(profile, start_date: start_date, end_date: end_date).total_results
          offset = 1
          while total_results.positive?
            begin
              # p "total_results: #{total_results}, offset: #{offset}"
              # If you don't give a date range, you get one month by default
              # If you don't give a limit, you get 1000 rows by default
              # Also: GA will only return up to 10_000 rows for any request
              Pageview.results(profile, start_date: start_date, end_date: end_date, limit: 10_000, offset: offset).each do |entry|
                page_path = entry.pagePath.gsub(/\?.*$/, "")
                noid = find_match(page_path)
                next if noid.nil?

                ga = GoogleAnalyticsHistory.new
                ga.noid = noid
                ga.original_date = entry.date
                ga.page_path = entry.pagePath
                ga.pageviews = entry.pageviews.to_i
                ga.save! if ga.valid? # only save if it's new data
              end
              offset += 10_000
              total_results -= 10_000
            rescue Faraday::TimeoutError, Faraday::ConnectionFailed
              # we're just going to try again by not incrementing/decrementing the offset/total_results
            end
          end
        end
      rescue OAuth2::Error => e
        p "OAUTH ERROR: #{e.code["message"]}"
      end
    end
  end
end

def regex_mapping
  [
    Regexp.new("^/concern/file_sets/([a-z0-9]{9})$"),
    Regexp.new("^/concern/monographs/([a-z0-9]{9})$"),
    Regexp.new("^/epub/([a-z0-9]{9})$"),
    Regexp.new("^/epubs_download_.*?/([a-z0-9]{9})$"),
    Regexp.new("^/concern/scores/([a-z0-9]{9})$")
  ]
end

def find_match(url)
  regex_mapping.each do |regex|
    if regex.match?(url)
      return regex.match(url)[1]
    end
  end
  return nil
end
