# frozen_string_literal: true

module Greensub
  class << self
    def product_include?(product:, entity:)
      return false unless product.present? && entity.present?
      noids = product.components.map(&:noid)
      noids.include?(entity.noid)
    end
  end
end
