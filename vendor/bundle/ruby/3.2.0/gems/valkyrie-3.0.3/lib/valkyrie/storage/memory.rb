# frozen_string_literal: true
module Valkyrie::Storage
  # Implements the DataMapper Pattern to store binary data in memory
  #
  # @note this adapter is used primarily for testing, and is not recommended
  #   in cases where you want to preserve real data
  class Memory
    attr_reader :cache
    def initialize
      @cache = {}
    end

    # @param file [IO]
    # @param original_filename [String]
    # @param resource [Valkyrie::Resource]
    # @param _extra_arguments [Hash] additional arguments which may be passed to other adapters
    # @return [Valkyrie::StorageAdapter::StreamFile]
    def upload(file:, original_filename:, resource: nil, **_extra_arguments)
      identifier = Valkyrie::ID.new("memory://#{resource.id}")
      cache[identifier] = Valkyrie::StorageAdapter::StreamFile.new(id: identifier, io: file)
    end

    # Return the file associated with the given identifier
    # @param id [Valkyrie::ID]
    # @return [Valkyrie::StorageAdapter::StreamFile]
    # @raise Valkyrie::StorageAdapter::FileNotFound if nothing is found
    def find_by(id:)
      raise Valkyrie::StorageAdapter::FileNotFound unless cache[id]
      cache[id]
    end

    # @param id [Valkyrie::ID]
    # @return [Boolean] true if this adapter can handle this type of identifer
    def handles?(id:)
      id.to_s.start_with?("memory://")
    end

    # Delete the file on disk associated with the given identifier.
    # @param id [Valkyrie::ID]
    def delete(id:)
      cache.delete(id)
      nil
    end
  end
end
