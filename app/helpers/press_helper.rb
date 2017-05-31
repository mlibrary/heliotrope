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

  def name(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.name if press.present?
  end

  def logo(subdomain)
    press = Press.where(subdomain: subdomain).first
    # the url method puts a forward-slash here that...
    # doesn't suit image_tag. Removing it.
    press.logo_path.url.sub('/', '') if press.present?
  end

  def footer_block_a(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.footer_block_a if press.present?
  end

  def footer_block_c(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.footer_block_c if press.present?
  end

  def url(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.press_url if press.present?
  end

  def google_analytics(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.google_analytics if press.present?
  end

  def typekit(subdomain)
    press = Press.where(subdomain: subdomain).first
    press.typekit if press.present?
  end
end
