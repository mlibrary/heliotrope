# frozen_string_literal: true

module PressHelper
  # Get the subdomain from any view that would have one
  def press_subdomain
    if defined?(@press.subdomain)
      @press.subdomain
    elsif defined?(@monograph_presenter.subdomain)
      @monograph_presenter.subdomain
    elsif defined?(@presenter.monograph.subdomain)
      @presenter.monograph.subdomain
    end
  end

  def press_subdomains(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    [press.subdomain, parent_press(press)&.subdomain].compact
  end

  def name(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    press.name if press.present?
  end

  def logo(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    press.present? ? press.logo_path_url : 'fulcrum-white-50px.png'
  end

  def url(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    press.press_url if press.present?
  end

  # These are not required. If there's no value we'll try to get the parent's (if one exists)

  def footer_block_a(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    if press.footer_block_a.blank?
      parent_press(press)&.footer_block_a
    else
      press.footer_block_a
    end
  end

  def footer_block_c(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    if press.footer_block_c.blank?
      parent_press(press)&.footer_block_c
    else
      press.footer_block_c
    end
  end

  def google_analytics(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    if press.google_analytics.blank?
      parent_press(press)&.google_analytics
    else
      press.google_analytics
    end
  end

  def typekit(subdomain)
    press = Press.where(subdomain: subdomain)&.first
    return if press.blank?
    if press.typekit.blank?
      parent_press(press)&.typekit
    else
      press.typekit
    end
  end

  private

    def parent_press(child_press)
      Press.find(child_press.parent_id) if child_press.parent_id.present?
    end
end
