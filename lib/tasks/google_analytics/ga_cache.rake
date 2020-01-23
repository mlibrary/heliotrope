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
          # HELIO-2949
          # Pageviews used to be here but are now in their own task, add_ga_history.rake
          # Because pageviews are no longer here, and the Pageview class is the first class in
          # app/models/pageview.rb with the other GA classes coming after in the same file,
          # this task was failing when run from cron with:
          # rake aborted!
          # NameError: uninitialized constant GASessions
          # /hydra-dev/heliotrope-preview/releases/20190919143602/lib/tasks/ga_cache.rake:16:in `block (2 levels) in <top (required)>'
          # well, maybe that's why. But adding this line seems to stop that problem.
          # HELIO-2972
          load 'app/models/pageview.rb'

          # ALSO! As of 09/2019 it seems to me that none of this cached data is actually being
          # used anywhere in the app. I think we might have removed the view for this stuff
          # a long time ago. But the cron is still there, and fetching this isn't at all
          # resource intensive, and there's not much code to maintain. So I'm going to
          # leave it alone. Maybe we'll use it someday.

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
