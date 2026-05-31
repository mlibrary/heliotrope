# frozen_string_literal: true
module ActiveTriples
  ##
  # Default property applying strategy which just copies all configured properties
  # from a data property to a new resource, assuming it supports the #property
  # interface.
  class ExtensionStrategy
    class << self
      # @param [ActiveTriples::Resource, #property] resource A resource to copy
      #   the property to.
      # @param [ActiveTriples::Property] property The property to copy.
      def apply(resource, property)
        resource.property(property.name, property.to_h, &property.config)
      end
    end
  end
end
