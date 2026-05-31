# frozen_string_literal: true
module ActiveTriples
  ##
  # Defines a generic RDF `Resource` as an `ActiveTriples::Entity`. This
  # provides a basic `Entity` type for classless resources.
  class Resource
    include RDFSource

    class << self
      def type_registry
        RDFSource.type_registry
      end

      def property(*)
        raise "Properties not definable directly on ActiveTriples::Resource, use a subclass" if
          self == ActiveTriples::Resource
        super
      end
    end
  end
end
