module AnalyticsPresenter
  extend ActiveSupport::Concern

  def pageviews_by_path(path)
    count = 0
    profile = google_analytics_profile
    if profile.present?
      Pageview.results(profile).each do |entry|
        count += entry[:pageviews].to_i if entry[:pagePath] == path
      end
    end
    return count
  end

  def pageviews_by_ids(ids)
    count = 0
    profile = google_analytics_profile
    if profile.present?
      Pageview.results(profile).each do |entry|
        ids.each do |id|
          count += entry[:pageviews].to_i if entry[:pagePath].include? id
        end
      end
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
