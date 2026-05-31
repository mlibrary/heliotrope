# frozen_string_literal: true
module Valkyrie::Persistence::Solr
  # Provides access to generic methods for converting to/from
  # {Valkyrie::Resource} and hashes for persistence into Solr.
  class ResourceFactory
    require 'valkyrie/persistence/solr/orm_converter'
    require 'valkyrie/persistence/solr/model_converter'
    attr_reader :resource_indexer, :adapter
    delegate :id, to: :adapter, prefix: true

    # @param [Valkyrie::Persistence::Solr::MetadataAdapter::NullIndexer] resource_indexer
    # @param [Valkyrie::Persistence::Solr::MetadataAdapter] adapter
    def initialize(resource_indexer:, adapter:)
      @resource_indexer = resource_indexer
      @adapter = adapter
    end

    # @param object [Hash] The solr document in a hash to convert to a
    #   resource.
    # @return [Valkyrie::Resource]
    def to_resource(object:)
      ORMConverter.new(object, resource_factory: self).convert!
    end

    # @param resource [Valkyrie::Resource] The resource to convert to a solr hash.
    # @return [Hash] The solr document represented as a hash.
    def from_resource(resource:)
      Valkyrie::Persistence::Solr::ModelConverter.new(resource, resource_factory: self).convert!
    end
  end
end
