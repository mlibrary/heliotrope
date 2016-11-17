module AnalyticsPresenter
  extend ActiveSupport::Concern

  def pageviews_by_path(path)
    count = 0
    begin
      profile = google_analytics_profile
      if profile.present?
        Pageview.results(profile).each do |entry|
          count += entry[:pageviews].to_i if entry[:pagePath] == path
        end
      end
    rescue OAuth2::Error => e
      Rails.logger.error(e.code["message"])
    end
    return count
  end

  def pageviews_by_ids(ids)
    count = 0
    begin
      profile = google_analytics_profile
      if profile.present?
        Pageview.results(profile).each do |entry|
          ids.each do |id|
            count += entry[:pageviews].to_i if entry[:pagePath].include? id
          end
        end
      end
    rescue OAuth2::Error => e
      # TODO: we're hitting GA quotas for monograph_catalog pages in production.
      # Need to figure out a better way to do this...
      Rails.logger.error(e.code["message"])
      return nil
    end
    return count
  end

  def google_analytics_id
    press = Press.find_by(subdomain: subdomain)
    return press.google_analytics unless press.nil? || press.google_analytics.nil?
    Rails.application.secrets.google_analytics_id
  end

  def google_analytics_profile
    profile = AnalyticsService.profile(google_analytics_id)
    unless profile
      Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
      return []
    end
    return profile
  end
end
