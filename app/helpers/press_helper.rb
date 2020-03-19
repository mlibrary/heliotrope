# frozen_string_literal: true

module PressHelper
  # Get the subdomain from any view that would have one
  def press_subdomain
    if defined?(@press.subdomain)
      @press.subdomain
    elsif defined?(@presenter.subdomain)
      @presenter.subdomain
    elsif defined?(@presenter.parent.subdomain)
      @presenter.parent.subdomain
    end
  end

  def press_subdomains(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return [] if press.blank?
    [press.subdomain.presence, parent_press(press)&.subdomain.presence].compact
  end

  def name(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    press&.name.presence || ''
  end

  def logo(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    press&.logo_path_url.presence || 'fulcrum-white-50px.png'
  end

  def url(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    press&.press_url.presence || ''
  end

  # These are not required. If there's no value we'll try to get the parent's (if one exists)

  def footer_block_a(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.footer_block_a.presence || parent_press(press)&.footer_block_a.presence
  end

  def footer_block_b(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.footer_block_b.presence || parent_press(press)&.footer_block_b.presence
  end

  def footer_block_c(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.footer_block_c.presence || parent_press(press)&.footer_block_c.presence
  end

  def navigation_block(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.navigation_block.presence || parent_press(press)&.navigation_block.presence
  end

  def google_analytics(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.google_analytics.presence || parent_press(press)&.google_analytics.presence
  end

  def google_analytics_url(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.google_analytics_url.presence || parent_press(press)&.google_analytics_url.presence
  end

  def readership_map_url(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.readership_map_url.presence || parent_press(press)&.readership_map_url.presence
  end

  def typekit(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.typekit.presence || parent_press(press)&.typekit.presence
  end

  def twitter(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.twitter.presence || parent_press(press)&.twitter.presence
  end

  def location(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.location.presence || parent_press(press)&.location.presence
  end

  def restricted_message(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    press.restricted_message.presence || parent_press(press)&.restricted_message.presence
  end

  def show_banner?(actor, subdomain) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return false unless controller.is_a?(PressCatalogController) || controller.is_a?(::MonographCatalogController)
    return false if subdomain.blank?
    product = banner_product(subdomain)
    return false unless product.present? && product.name.present? && product.purchase.present?
    return false if Greensub.actor_products(actor).include?(product)
    return true if controller.is_a?(PressCatalogController)
    monograph = Sighrax.from_noid(@presenter&.id)
    return false unless monograph.valid?
    return false if Sighrax.open_access?(monograph)
    Greensub.product_include?(product: product, entity: monograph)
  end

  def banner_product(subdomain)
    case subdomain
    when 'michigan'
      Greensub::Product.find_by(identifier: 'ebc_backlist')
    when 'heliotrope'
      Greensub::Product.find_by(identifier: 'nag_' + Time.current.year.to_s)
    end
  end

  def banner_message
    controller.is_a?(PressCatalogController) ? 'press_catalog.banner' : 'monograph_catalog.banner'
  end

  def all_google_analytics(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return [] if press.blank?
    [press.google_analytics.presence, parent_press(press)&.google_analytics.presence].compact
  end

  private

    def parent_press(child_press)
      Press.find(child_press.parent_id) if child_press.parent_id.present?
    end
end
