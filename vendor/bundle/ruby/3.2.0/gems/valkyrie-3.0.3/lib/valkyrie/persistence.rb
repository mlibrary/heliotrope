# frozen_string_literal: true
module Valkyrie
  # This is a namespacing module for metadata persisters as per the DataMapper pattern
  #  https://en.wikipedia.org/wiki/Data_mapper_pattern
  #
  # @note These persisters do not store binary content.
  #       See Valkyrie::Storage for persisting binary content (files).
  #
  # @example Register persisters in an initializer using Valkyrie::MetadataAdapter.register
  #   Valkyrie::MetadataAdapter.register(
  #     Valkyrie::Persistence::Memory::MetadataAdapter.new,
  #     :memory
  #   )
  #
  # @example Retrieve a registered persister using Valkyrie::MetadataAdapter.find
  #   Valkyrie::MetadataAdapter.find(:memory)
  #   => <Valkyrie::Persistence::Memory::MetadataAdapter:0x007fa6ec031bd8>
  #
  # @example Saving an object
  #
  #   object1 = MyModel.new title: 'My Cool Object', authors: ['Jones, Alice', 'Smith, Bob']
  #   object1 = Valkyrie.config.metadata_adapter.persister.save(model: object1)
  #
  # @see https://github.com/samvera-labs/valkyrie/wiki/Persistence
  # @see lib/valkyrie/specs/shared_specs/persister.rb
  #
  module Persistence
    require 'valkyrie/persistence/optimistic_lock_token'
    require 'valkyrie/persistence/custom_query_container'
    require 'valkyrie/persistence/memory'
    require 'valkyrie/persistence/composite_persister'
    require 'valkyrie/persistence/delete_tracking_buffer'
    require 'valkyrie/persistence/buffered_persister'
    require 'valkyrie/persistence/shared'
    autoload :Postgres, 'valkyrie/persistence/postgres'
    autoload :Solr, 'valkyrie/persistence/solr'
    autoload :Fedora, 'valkyrie/persistence/fedora'
    class ObjectNotFoundError < StandardError
    end

    class UnsupportedDatatype < StandardError
    end

    class StaleObjectError < StandardError
    end

    module Attributes
      OPTIMISTIC_LOCK = :optimistic_lock_token
    end
  end
end
