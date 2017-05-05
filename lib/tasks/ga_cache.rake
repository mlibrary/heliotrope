# frozen_string_literal: true

desc "cache google analytics data"
namespace :heliotrope do
  task ga_cache: :environment do
    cached = []
    ga_id = Rails.application.secrets.google_analytics_id
    if ga_id.present?
      begin
        # Right now this grabs the first "view" which is currently the "unfiltered" view
        # To change this we'd need to add the "account_id" (not GA id) in a config file somewhere
        profile = AnalyticsService.profile(ga_id)
        if profile.present?
          # If you don't give a date range, you get one month by default
          # If you don't give a limit, you get 1000 rows by default
          Pageview.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 100_000).each do |entry|
            cached << entry
          end
          Rails.cache.write('ga_pageviews', cached)
          Rails.logger.info("Wrote ga_pageviews to cache")
        else
          Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
        end
      rescue OAuth2::Error => e
        Rails.logger.error(e.code["message"])
      end
    end
  end
end
