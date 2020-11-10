# frozen_string_literal: true

module BannerHelper
  def show_banner?(actor, subdomain) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return false unless controller.is_a?(PressCatalogController) || controller.is_a?(::MonographCatalogController)
    return false if subdomain.blank?
    product = banner_product(subdomain)
    return false unless product.present? && product.name.present? && product.purchase.present?
    return false if Sighrax.actor_products(actor).include?(product)
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
    else
      parent = Sighrax::Publisher.from_subdomain(subdomain).parent
      return nil unless parent.valid?
      banner_product(parent.subdomain)
    end
  end

  def banner_message
    controller.is_a?(PressCatalogController) ? 'press_catalog.banner' : 'monograph_catalog.banner'
  end

  def show_eula?(subdomain)
    return false unless controller.is_a?(PressCatalogController) || controller.is_a?(::MonographCatalogController)
    %w[barpublishing].include? subdomain
  end
end
