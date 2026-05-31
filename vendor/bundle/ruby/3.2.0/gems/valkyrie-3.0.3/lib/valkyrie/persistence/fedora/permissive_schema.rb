# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  # Default schema for Fedora MetadataAdapter. It's used to generate a mapping
  # of {Valkyrie::Resource} attributes to predicates. This implementation will
  # make up a URI if one doesn't exist in a passed in schema.
  #
  # @example Passing in a mapping
  #   schema = Valkyrie::Persistence::Fedora::PermissiveSchema.new(member_ids:
  #     RDF::URI("http://example.com/member_ids"))
  #   schema.predicate_for(resource: Resource.new, property: :member_ids) # => RDF::URI<"http://example.com/member_ids">
  #   schema.predicate_for(resource: Resource.new, property: :unknown) # => RDF::URI<"http://example.com/predicate/unknown">
  class PermissiveSchema
    URI_PREFIX = 'http://example.com/predicate/'

    # @return [RDF::URI]
    def self.valkyrie_id
      uri_for('valkyrie_id')
    end

    # @return [RDF::URI]
    def self.id
      uri_for(:id)
    end

    # @return [RDF::URI]
    def self.member_ids
      uri_for(:member_ids)
    end

    # @return [RDF::URI]
    def self.valkyrie_bool
      uri_for(:valkyrie_bool)
    end

    # @return [RDF::URI]
    def self.valkyrie_datetime
      uri_for(:valkyrie_datetime)
    end

    # @return [RDF::URI]
    def self.valkyrie_float
      uri_for(:valkyrie_float)
    end

    # @return [RDF::URI]
    def self.valkyrie_int
      uri_for(:valkyrie_int)
    end

    # @return [RDF::URI]
    def self.valkyrie_time
      uri_for(:valkyrie_time)
    end

    # @return [RDF::URI]
    def self.optimistic_lock_token
      uri_for(:optimistic_lock_token)
    end

    # Cast the property to a URI in the namespace
    # @param property [Symbol]
    # @return [RDF::URI]
    def self.uri_for(property)
      RDF::URI("#{URI_PREFIX}#{property}")
    end

    attr_reader :schema

    # @param schema [Hash] the structure used to store the mapping between property names and predicates
    def initialize(schema = {})
      @schema = schema
    end

    # Find the predicate in the schema for the Valkyrie property
    # If this does not exist, a URI using the property name prefixed by URI_PREFIX generates it
    # @param resource [Valkyrie::Resource]
    # @param property [String]
    # @return [RDF::URI]
    def predicate_for(resource:, property:)
      schema.fetch(property) { self.class.uri_for(property) }
    end

    # Find the property in the schema. If it's not there check to see
    # if this prediate is in the URI_PREFIX namespace, return the suffix as the property
    # @example:
    #   property_for(resource: nil, predicate: "http://example.com/predicate/internal_resource")
    #   #=> 'internal_resource'
    # @param resource [Valkyrie::Resource]
    # @param predicate [RDF::URI, String]
    # @return [String]
    def property_for(resource:, predicate:)
      existing_predicates = schema.find { |_k, v| v == RDF::URI(predicate.to_s) }
      predicate_name = predicate.to_s.gsub(URI_PREFIX, '')

      return predicate_name if existing_predicates.blank?
      existing_predicates.first
    end
  end
end
