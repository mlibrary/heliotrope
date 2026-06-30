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

  def all_google_analytics_4
    [@press.google_analytics_4.presence, parent_press(@press)&.google_analytics_4.presence].compact
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

  def content_warning_information
    @press&.content_warning_information.presence || ''
  end

  def show_irus_stats?
    return false if press.show_irus_stats == false
    true
  end

  def accessibility_webpage_url
    @press&.accessibility_webpage_url.presence
  end

  def show_accessibility_metadata?
    return false if press.show_accessibility_metadata == false
    true
  end

  def show_request_accessible_copy_button?
    return false if press.show_request_accessible_copy_button == false
    true
  end

  def accessible_copy_request_form_url
    @press&.accessible_copy_request_form_url.presence
  end

  # Returns a hex color string for the press loading-bar brand color.
  # Used to theme the pdf.js #loadingBar inside the iframe (--progressBar-color).
  # Falls back to #00afec (the old cozy-honey-bear default) for unrecognised presses.
  BRAND_COLORS = {
    'aberdeenunipress' => '#111D2F',
    'ahpi'             => '#80561B',
    'amherst'          => '#311a4d',
    'aperio'           => '#E57200',
    'a2ru'             => '#64b145',
    'atg'              => '#333333',
    'barpublishing'    => '#d40b13',
    'belin'            => '#00274c',
    'bigten'           => '#393D42',
    'boydellandbrewer' => '#005159',
    'bridwell'         => '#354ca1',
    'fia'              => '#00274c',
    'gabii'            => '#1b2f43',
    'heb'              => '#333333',
    'icmc'             => '#002e5e',
    'leverpress'       => '#003352',
    'livedplaces'      => '#BF3C01',
    'maizebooks'       => '#002e5e',
    'michigan'         => '#00274C',
    'michelt'          => '#00274C',
    'mps'              => '#1d7491',
    'msupress'         => '#18453B',
    'ncid'             => '#00274c',
    'newprairiepress'  => '#26183F',
    'nyupress'         => '#57068c',
    'rekihaku'         => '#111111',
    'sarpress'         => '#a75534',
    'seas'             => '#00274c',
    'sussex'           => '#C54B20',
    'um-pccn'          => '#00274c',
    'uncpress'         => '#0D7686',
    'vermont'          => '#154734',
    'westminster'      => '#B13C32'
  }.freeze

  def brand_color
    press_subdomains.each do |sub|
      color = BRAND_COLORS[sub]
      return color if color
    end
    '#00afec'
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

  def blank?
    true
  end

  def press_subdomains
    []
  end

  def all_google_analytics
    []
  end

  def all_google_analytics_4
    []
  end

  def brand_color
    '#00afec'
  end

  def method_missing(name, *args, &block)
    Rails.logger.error("PressPresenterNullObject has no #{name} method")
    ""
  end
end
