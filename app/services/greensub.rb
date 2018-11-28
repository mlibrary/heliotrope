# frozen_string_literal: true

module Greensub
  class << self
    def actor_product_list(actor)
      return [] unless ValidationService.valid_actor?(actor)
      products = actor.individual&.products || []
      actor.institutions.each do |institution|
        products += institution.products
      end
      products.uniq
    end
  end
end
