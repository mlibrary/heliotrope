# frozen_string_literal: true
module Valkyrie::Persistence::Memory
  # MetadataAdapter for the memory adapter.
  # @see Valkyrie::Persistence::Memory
  # @note Documentation for instance methods on other MetadataAdapters are
  #   copied from the Memory implementation via `(see
  #   Valkyrie::Persistence::Memory#method)` to reduce duplication.
  class MetadataAdapter
    attr_writer :cache

    # @return [Valkyrie::Persistence::Memory::Persister] A memory persister for
    #   this adapter.
    def persister
      Valkyrie::Persistence::Memory::Persister.new(self)
    end

    # @return [Valkyrie::Persistence::Memory::QueryService] A query service for
    #   this adapter.
    def query_service
      @query_service ||= Valkyrie::Persistence::Memory::QueryService.new(adapter: self)
    end

    # @return [Hash] The in-memory data cache.
    def cache
      @cache ||= {}
    end

    # @return [Valkyrie::ID] Identifier for this metadata adapter.
    def id
      @id ||= Valkyrie::ID.new(Digest::MD5.hexdigest(self.class.to_s))
    end
  end
end
