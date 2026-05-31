# frozen_string_literal: true
module Valkyrie::Persistence
  # Implements the DataMapper Pattern to proxy another Metadata Persister
  #
  # Provides with_buffer to send multiple updates at one time to the proxied persister
  #  In some cases this will realize performance gains
  #
  # @example
  #     buffered_persister.with_buffer do |persist, buffer|
  #       yield Valkyrie::AdapterContainer.new(persister: persist, query_service: metadata_adapter.query_service)
  #       buffer.persister.deletes.uniq(&:id).each do |delete|
  #         index_persister.delete(resource: delete)
  #       end
  #       index_persister.save_all(resources: buffer.query_service.find_all)
  #     end
  #
  # @see Valkyrie::Persistence::DeleteTrackingBuffer for more information on deletes used in the example above
  #
  class BufferedPersister
    attr_reader :persister, :buffer_class
    delegate :adapter, :wipe!, to: :persister
    def initialize(persister, buffer_class: Valkyrie::Persistence::DeleteTrackingBuffer)
      @persister = persister
      @buffer_class = buffer_class
    end

    def save(resource:, external_resource: false)
      persister.save(resource: resource, external_resource: external_resource)
    end

    def save_all(resources:)
      persister.save_all(resources: resources)
    end

    def delete(resource:)
      persister.delete(resource: resource)
    end

    def with_buffer
      memory_buffer = buffer_class.new
      yield [Valkyrie::Persistence::CompositePersister.new(self, memory_buffer.persister), memory_buffer]
    end
  end
end
