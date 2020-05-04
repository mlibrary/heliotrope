# frozen_string_literal: true

class PressPresenter < ApplicationPresenter
  attr_reader :subdomain, :press
  private_class_method :new

  def self.for(subdomain)
    return PressPresenterNullObject.new if subdomain.blank?
    press = Press.where(subdomain: subdomain).first
    return PressPresenterNullObject.new if press.blank?
    new(subdomain, press)
  end

  def press_subdomain
    @subdomain
  end

  def press_subdomains
    [@subdomain.presence, parent_press(@press)&.subdomain.presence].compact
  end

  def all_google_analytics
    [@press.google_analytics.presence, parent_press(@press)&.google_analytics.presence].compact
  end

  def name
    @press&.name.presence || ''
  end

  def logo
    @press&.logo_path_url.presence || 'fulcrum-white-50px.png'
  end

  def url
    @press&.press_url.presence || ''
  end

  def description
    @press&.description.presence || ''
  end

  # These are not required. If there's no value we'll try to get the parent's (if one exists)

  def footer_block_a
    @press.footer_block_a.presence || parent_press(@press)&.footer_block_a.presence
  end

  def footer_block_b
    @press.footer_block_b.presence || parent_press(@press)&.footer_block_b.presence
  end

  def footer_block_c
    @press.footer_block_c.presence || parent_press(@press)&.footer_block_c.presence
  end

  def navigation_block
    @press.navigation_block.presence || parent_press(@press)&.navigation_block.presence
  end

  def google_analytics
    @press.google_analytics.presence || parent_press(@press)&.google_analytics.presence
  end

  def google_analytics_url
    # can't use parent's value here, each press must have its own https://tools.lib.umich.edu/jira/browse/HELIO-3362
    @press.google_analytics_url.presence
  end

  def readership_map_url
    # can't use parent's value here, each press must have its own https://tools.lib.umich.edu/jira/browse/HELIO-3362
    @press.readership_map_url.presence
  end

  def typekit
    @press.typekit.presence || parent_press(@press)&.typekit.presence
  end

  def twitter
    @press.twitter.presence || parent_press(@press)&.twitter.presence
  end

  def location
    @press.location.presence || parent_press(@press)&.location.presence
  end

  def restricted_message
    @press.restricted_message.presence || parent_press(@press)&.restricted_message.presence
  end

  private

    def initialize(subdomain, press)
      @subdomain = subdomain
      @press = press
    end

    def parent_press(child_press)
      Press.find(child_press.parent_id) if child_press.parent_id.present?
    end
end

class PressPresenterNullObject
  attr_reader :subdomain, :press

  def initialize
    @subdomain = ""
    @press = ""
  end

  def present?
    false
  end

  def press_subdomains
    []
  end

  def all_google_analytics
    []
  end

  def method_missing(name, *args, &block)
    Rails.logger.error("PressPresenterNullObject has no #{name} method")
    ""
  end
end
