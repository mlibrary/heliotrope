# frozen_string_literal: true
module ActiveTriples
  ##
  # Super class which provides a simple property DSL for defining property ->
  # predicate mappings.
  # 
  # @example defining and applying a custom schema
  #   class MySchema < ActiveTriples::Schema
  #     property :title,   predicate: RDF::Vocab::DC.title
  #     property :creator, predicate: RDF::Vocab::DC.creator, other: :options
  #   end
  #
  #   resource = Class.new { include ActiveTriples::RDFSource }
  #   resource.apply_schema(MySchema)
  #
  class Schema
    class << self
      ##
      # Define a property.
      #
      # @param [Symbol] property The property name on the object.
      # @param [Hash] options Options for the property.
      # @option options [Boolean] :cast
      # @option options [String, Class] :class_name 
      # @option options [RDF::URI] :predicate The predicate to map the property
      #   to.
      #
      # @see ActiveTriples::Property for more about options
      def property(property, options)
        properties << Property.new(options.merge(:name => property))
      end
      
      ##
      # @return [Array<ActiveTriples::Property>]
      def properties
        @properties ||= []
      end
    end
  end
end
