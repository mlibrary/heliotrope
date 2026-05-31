# frozen_string_literal: true
require 'valkyrie/persistence/postgres/orm_converter'
require 'valkyrie/persistence/postgres/resource_converter'
module Valkyrie::Persistence::Postgres
  # Provides access to generic methods for converting to/from
  # {Valkyrie::Resource} and {Valkyrie::Persistence::Postgres::ORM::Resource}.
  class ResourceFactory
    attr_reader :adapter
    delegate :id, to: :adapter, prefix: true

    # @param [MetadataAdapter] adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    # @param object [Valkyrie::Persistence::Postgres::ORM::Resource] AR
    #   record to be converted.
    # @return [Valkyrie::Resource] Model representation of the AR record.
    def to_resource(object:)
      ::Valkyrie::Persistence::Postgres::ORMConverter.new(object, resource_factory: self).convert!
    end

    # @param resource [Valkyrie::Resource] Model to be converted to ActiveRecord.
    # @return [Valkyrie::Persistence::Postgres::ORM::Resource] ActiveRecord
    #   resource for the Valkyrie resource.
    def from_resource(resource:)
      ::Valkyrie::Persistence::Postgres::ResourceConverter.new(resource, resource_factory: self).convert!
    end

    # Accessor for the ActiveRecord class which all Postgres resources are an
    # instance of.
    # @return [Class]
    def orm_class
      ::Valkyrie::Persistence::Postgres::ORM::Resource
    end
  end
end
