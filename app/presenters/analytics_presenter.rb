# frozen_string_literal: true

class AnalyticsPresenter
  attr_reader :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  def can_read?
    @current_user.platform_admin?
  end

  def users
    Rails.cache.read('ga_users') || 0
  end

  def sessions
    Rails.cache.read('ga_sessions') || 0
  end

  def page_views
    Rails.cache.read('ga_pageviews').nil? ? 0 : Rails.cache.read('ga_pageviews').count
  end

  def bounce_rate
    Rails.cache.read('ga_bouncerate') || 0.0
  end

  def top_pages
    top_ten('ga_pages')
  end

  def landing_pages
    top_ten('ga_landing_pages')
  end

  def channels
    top_ten('ga_channels')
  end

  def referrers
    top_ten('ga_referrers')
  end

  private

    def top_ten(cache_name)
      top = []
      ga_pages = Rails.cache.read(cache_name)
      return top unless ga_pages.is_a?(Array)
      last = [9, ga_pages.count - 1].min
      (0..last).each do |i|
        top << { name: ga_pages[i].pageTitle, count: ga_pages[i].pageviews }
      end
      top
    end
end
