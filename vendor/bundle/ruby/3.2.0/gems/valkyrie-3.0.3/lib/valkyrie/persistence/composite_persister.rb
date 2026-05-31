# frozen_string_literal: true
module Valkyrie::Persistence
  # Wraps up multiple persisters under a common interface, to transparently
  # persist to multiple places at once.
  #
  # @example
  #   persister = Valkyrie.config.metadata_adapter
  #   index_persister = Valkyrie::MetadataAdapter.find(:index_solr)
  #   Valkyrie::MetadataAdapter.register(
  #     Valkyrie::AdapterContainer.new(
  #       persister: Valkyrie::Persistence::CompositePersister.new(
  #         persister,
  #         index_persister
  #         )
  #       query_service: Valkyrie.config.metadata_adapter.query_service
  #     )
  #     :my_composite_persister
  #   )
  #
  class CompositePersister
    attr_reader :persisters
    def initialize(*persisters)
      @persisters = persisters
    end

    # (see Valkyrie::Persistence::Memory::Persister#save)
    def save(resource:, external_resource: false)
      # Assume the first persister is the canonical data store; that's the optlock we want
      first, *rest = *persisters
      cached_resource = first.save(resource: resource, external_resource: external_resource)
      # Don't pass opt lock tokens to other persisters
      internal_resource = cached_resource.dup
      internal_resource.clear_optimistic_lock_token!
      rest.inject(internal_resource) { |m, persister| persister.save(resource: m, external_resource: true) }
      # return the one with the desired opt lock token
      cached_resource
    end

    # (see Valkyrie::Persistence::Memory::Persister#save_all)
    def save_all(resources:)
      resources.map do |resource|
        save(resource: resource)
      end
    rescue Valkyrie::Persistence::StaleObjectError
      # clear out any IDs returned to reduce potential confusion
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process."
    end

    # (see Valkyrie::Persistence::Memory::Persister#delete)
    def delete(resource:)
      persisters.inject(resource) { |m, persister| persister.delete(resource: m) }
    end

    def wipe!
      persisters.each_entry(&:wipe!)
    end
  end
end
