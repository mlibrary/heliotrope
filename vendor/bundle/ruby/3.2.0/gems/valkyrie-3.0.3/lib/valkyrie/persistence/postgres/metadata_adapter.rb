# frozen_string_literal: true
require 'valkyrie/persistence/postgres/persister'
require 'valkyrie/persistence/postgres/query_service'
module Valkyrie::Persistence::Postgres
  # Metadata Adapter for Postgres Adapter.
  #
  # This adapter uses ActiveRecord to persist resources in a JSON-B column named
  # `metadata`. This requires setting up a database.
  #
  # @see https://github.com/samvera-labs/valkyrie/wiki/Set-up-Valkyrie-database-in-a-Rails-Application
  class MetadataAdapter
    # @return [Class] {Valkyrie::Persistence::Postgres::Persister}
    def persister
      Valkyrie::Persistence::Postgres::Persister.new(adapter: self)
    end

    # @return [Class] {Valkyrie::Persistence::Postgres::QueryService}
    def query_service
      @query_service ||= Valkyrie::Persistence::Postgres::QueryService.new(
        resource_factory: resource_factory,
        adapter: self
      )
    end

    # @return [Class] {Valkyrie::Persistence::Postgres::ResourceFactory}
    def resource_factory
      @resource_factory ||= Valkyrie::Persistence::Postgres::ResourceFactory.new(adapter: self)
    end

    # Construct a Valkyrie ID object using an MD5 hash generated from the database URL
    # @return [Valkyrie::ID]
    def id
      @id ||= begin
        to_hash = "#{connection_configuration[:host]}:#{connection_configuration[:database]}"
        Valkyrie::ID.new(Digest::MD5.hexdigest(to_hash))
      end
    end

    private

    def connection_configuration
      if resource_factory.orm_class.respond_to?(:connection_db_config)
        resource_factory.orm_class.connection_db_config.configuration_hash
      else
        resource_factory.orm_class.connection_config
      end
    end
  end
end
