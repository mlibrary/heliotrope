# frozen_string_literal: true
require 'rsolr'
module Valkyrie::Persistence::Solr
  require 'valkyrie/persistence/solr/persister'
  require 'valkyrie/persistence/solr/query_service'
  require 'valkyrie/persistence/solr/resource_factory'
  # MetadataAdapter for Solr Adapter.
  #
  # This adapter persists resources as hashes to an RSolr connection.
  #
  # @example Instantiate a Solr MetadataAdapter for Blacklight
  #   Valkyrie::Persistence::Solr::MetadataAdapter.new(
  #     connection: Blacklight.default_index.connection
  #   )
  #
  # @example Instantiate a Solr MetadataAdapter with just RSolr
  #   Valkyrie::Persistence::Solr::MetadataAdapter.new(
  #     connection: RSolr.connect(url: "http://127.0.0.1:8983/solr/core")
  #   )
  #
  # @example Instantiate a Solr MetadataAdapter with custom indexers
  #   Valkyrie::Persistence::Solr::MetadataAdapter.new(
  #     connection: Blacklight.default_index.connection,
  #     resource_indexer: CompositeIndexer.new(
  #       Valkyrie::Indexers::AccessControlsIndexer,
  #       MyIndexer
  #     )
  #   )
  class MetadataAdapter
    attr_reader :connection, :resource_indexer, :write_only
    # @param connection [RSolr::Client] The RSolr connection to index to.
    # @param resource_indexer [Class, #to_solr] An indexer which is able to
    #   receive a `resource` argument and then has an instance method `#to_solr`
    # @param write_only [Boolean] If true act as a write only adapter.
    # @param soft_commit [Boolean] If false, don't soft commit.
    def initialize(connection:, resource_indexer: NullIndexer, write_only: false, soft_commit: true)
      @connection = connection
      @resource_indexer = resource_indexer
      @write_only = write_only
      @soft_commit = soft_commit
    end

    # @return [Valkyrie::Persistence::Solr::Persister] The solr persister.
    def persister
      @persister ||= Valkyrie::Persistence::Solr::Persister.new(adapter: self)
    end

    def write_only?
      write_only
    end

    def soft_commit?
      @soft_commit
    end

    # @return [Valkyrie::Persistence::Solr::QueryService] The solr query
    #   service.
    def query_service
      @query_service ||= Valkyrie::Persistence::Solr::QueryService.new(
        connection: connection,
        resource_factory: resource_factory,
        adapter: self
      )
    end

    # Generate the Valkyrie ID for this unique metadata adapter
    # This uses the URL of the Solr endpoint to ensure that this is unique
    # @return [Valkyrie::ID]
    def id
      @id ||= Valkyrie::ID.new(Digest::MD5.hexdigest(connection.base_uri.to_s))
    end

    # @return [Valkyrie::Persistence::Solr::ResourceFactory] A resource factory
    #   to convert a resource to a solr document and back.
    def resource_factory
      Valkyrie::Persistence::Solr::ResourceFactory.new(resource_indexer: resource_indexer, adapter: self)
    end

    # Class modeling the indexer for cases where indexing is *not* performed
    class NullIndexer
      # @note this is a no-op
      def initialize(_); end

      # Generate the Solr hash
      # @return [Hash] this will be empty
      def to_solr
        {}
      end
    end
  end
end
