# frozen_string_literal: true

# HELIO-5000
# This is for cookie consent and other external analytics scripts that need to know
# the environment and GA4 ids.
class ExternalAnalyticsPresenter < ApplicationPresenter
  def initialize(controller, press_presenter)
    @controller = controller
    @press_presenter = press_presenter
  end

  def development?
    Rails.env.development? && primary_ga4_id?
  end

  def preview?
    Settings.host == "heliotrope-preview.hydra.lib.umich.edu" && primary_ga4_id?
  end

  # HELIO-4090, HELIO-4122
  # No GA4 analytics for LIT, monitoring, LOCKSS/CLOCKSS or Google Scholar
  def production?
    Settings.host == "www.fulcrum.org" &&
      primary_ga4_id? &&
      (@controller.current_institutions.map(&:identifier) & ["490", "2405", "2334", "2402"]).empty?
  end

  def primary_ga4_id?
    Rails.application.secrets.google_analytics_4_id.present?
  end

  def primary_ga4_id
    Rails.application.secrets.google_analytics_4_id
  end

  def press_ga4_ids
    if @press_presenter.present? && @press_presenter.all_google_analytics_4.present?
      @press_presenter.all_google_analytics_4 - [primary_ga4_id].compact
    else
      []
    end
  end

  def tag_manager_id?
    tag_manager_id.present?
  end

  def tag_manager_id
    return "GTM-PTZXSV7" if preview?
    return "GTM-K5L8F5XD" if production?
  end

  def hotjar_id?
    hotjar_id.present?
  end

  def hotjar_id
    return "2858980" if preview?
    return "2863753" if production?
  end
end
