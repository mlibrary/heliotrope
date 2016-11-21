desc "cache google analytics data"
namespace :heliotrope do
  task ga_cache: :environment do
    cached = []
    ga_id = Rails.application.secrets.google_analytics_id
    if ga_id.present?
      begin
        profile = AnalyticsService.profile(ga_id)
        if profile.present?
          Pageview.results(profile).each do |entry|
            cached << entry
          end
          Rails.cache.write('ga_pageviews', cached)
          Rails.logger.debug("Wrote ga_pageviews to cache")
        else
          Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
        end
      rescue OAuth2::Error => e
        Rails.logger.error(e.code["message"])
      end
    end
  end
end
