# frozen_string_literal: true

module BannerHelper
  def show_eula?(subdomain)
    return false unless controller.is_a?(PressCatalogController) || controller.is_a?(::MonographCatalogController)
    %w[barpublishing].include? subdomain
  end

  def show_acceptable_use_policy?(subdomain)
    return false unless controller.is_a?(PressCatalogController) || controller.is_a?(::MonographCatalogController)
    %w[barpublishing].exclude?(subdomain)
  end
end
