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
          # Also: GA will only return up to 10_000 rows for any request
          total_results = Pageview.results(profile, start_date: '2016-01-01', end_date: Date.today).total_results
          offset = 1

          while total_results.positive?
            Pageview.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 10_000, offset: offset).each do |entry|
              cached << entry
            end
            offset += 10_000
            total_results -= 10_000
          end

          Rails.cache.write('ga_pageviews', cached)
          Rails.logger.info("Wrote ga_pageviews to cache")

          GASessions.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 1).each do |entry|
            Rails.cache.write('ga_sessions', entry.sessions)
          end
          Rails.logger.info("Wrote ga_sessions to cache")
          GAUsers.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 1).each do |entry|
            Rails.cache.write('ga_users', entry.users)
          end
          Rails.logger.info("Wrote ga_users to cache")
          cached = []
          GAPages.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 100, sort: '-pageviews').each do |entry|
            cached << entry
          end
          Rails.cache.write('ga_pages', cached)
          Rails.logger.info("Wrote #{cached.count} ga_pages to cache")
          cached = []
          GALandingPages.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 100, sort: '-pageviews').each do |entry|
            cached << entry
          end
          Rails.cache.write('ga_landing_pages', cached)
          Rails.logger.info("Wrote #{cached.count} ga_landing_pages to cache")
          cached = []
          GAChannels.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 100, sort: '-pageviews').each do |entry|
            cached << entry
          end
          Rails.cache.write('ga_channels', cached)
          Rails.logger.info("Wrote #{cached.count} ga_channels to cache")
          cached = []
          GAReferrers.results(profile, start_date: '2016-01-01', end_date: Date.today, limit: 100, sort: '-pageviews').each do |entry|
            cached << entry
          end
          Rails.cache.write('ga_referrers', cached)
          Rails.logger.info("Wrote #{cached.count} ga_referrers to cache")
        else
          Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
        end
      rescue OAuth2::Error => e
        Rails.logger.error(e.code["message"])
      end
    end
  end
end
