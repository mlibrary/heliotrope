# frozen_string_literal: true
module Valkyrie::Persistence::Solr
  require 'valkyrie/persistence/solr/repository'
  # Persister for Solr MetadataAdapter.
  #
  # Most methods are delegated to {Valkyrie::Persistence::Solr::Repository}
  class Persister
    attr_reader :adapter
    delegate :connection, :query_service, :resource_factory, :write_only?, :soft_commit?, to: :adapter

    # @param adapter [Valkyrie::Persistence::Solr::MetadataAdapter] The adapter with the
    #   configured solr connection.
    def initialize(adapter:)
      @adapter = adapter
    end

    # (see Valkyrie::Persistence::Memory::Persister#save)
    # @return [Boolean] If write_only, whether saving succeeded.
    def save(resource:, external_resource: false)
      if write_only?
        repository([resource]).persist
      else
        raise Valkyrie::Persistence::ObjectNotFoundError, "The object #{resource.id} is previously persisted but not found at save time." unless external_resource || valid_for_save?(resource)
        repository([resource]).persist.first
      end
    end

    def valid_for_save?(resource)
      return true unless resource.persisted? # a new resource
      query_service.find_by(id: resource.id).present? # a persisted resource must be found
    end

    # (see Valkyrie::Persistence::Memory::Persister#save_all)
    # @return [Boolean] If write_only, whether saving succeeded.
    def save_all(resources:)
      repository(resources).persist
    end

    # (see Valkyrie::Persistence::Memory::Persister#delete)
    def delete(resource:)
      repository([resource]).delete.first
    end

    # (see Valkyrie::Persistence::Memory::Persister#wipe!)
    def wipe!
      connection.delete_by_query("*:*")
      connection.commit
    end

    # Constructs a Solr::Repository object for a set of Valkyrie Resources
    # @param [Array<Valkyrie::Resource>] resources
    # @return [Valkyrie::Persistence::Solr::Repository]
    def repository(resources)
      Valkyrie::Persistence::Solr::Repository.new(resources: resources, persister: self)
    end
  end
end
