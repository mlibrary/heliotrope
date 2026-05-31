# frozen_string_literal: true
module Valkyrie::Persistence::Solr
  require 'valkyrie/persistence/solr/queries'
  # Query Service for Solr MetadataAdapter.
  class QueryService
    attr_reader :connection, :resource_factory, :adapter
    # @param [RSolr::Client] connection
    # @param [Valkyrie::Persistence::Solr::ResourceFactory] resource_factory
    def initialize(connection:, resource_factory:, adapter:)
      @connection = connection
      @resource_factory = resource_factory
      @adapter = adapter
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_by)
    def find_by(id:)
      id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
      validate_id(id)
      Valkyrie::Persistence::Solr::Queries::FindByIdQuery.new(id, connection: connection, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_by_alternate_identifier)
    def find_by_alternate_identifier(alternate_identifier:)
      alternate_identifier = Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
      validate_id(alternate_identifier)
      Valkyrie::Persistence::Solr::Queries::FindByAlternateIdentifierQuery.new(alternate_identifier, connection: connection, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_many_by_ids)
    def find_many_by_ids(ids:)
      ids.map! do |id|
        id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
        validate_id(id)
        id
      end
      Valkyrie::Persistence::Solr::Queries::FindManyByIdsQuery.new(ids, connection: connection, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_all)
    def find_all
      Valkyrie::Persistence::Solr::Queries::FindAllQuery.new(connection: connection, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_all_of_model)
    def find_all_of_model(model:)
      Valkyrie::Persistence::Solr::Queries::FindAllQuery.new(connection: connection, resource_factory: resource_factory, model: model).run
    end

    # Count all of the Valkyrie Resources of a model persisted in the Solr index
    # @param [Class, String] model the Valkyrie::Resource Class
    # @return integer
    def count_all_of_model(model:)
      Valkyrie::Persistence::Solr::Queries::FindAllQuery.new(connection: connection, resource_factory: resource_factory, model: model).count
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_parents)
    def find_parents(resource:)
      find_inverse_references_by(resource: resource, property: :member_ids)
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_members)
    def find_members(resource:, model: nil)
      Valkyrie::Persistence::Solr::Queries::FindMembersQuery.new(
        resource: resource,
        model: model,
        connection: connection,
        resource_factory: resource_factory
      ).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_references_by)
    def find_references_by(resource:, property:, model: nil)
      result =
        if ordered_property?(resource: resource, property: property)
          Valkyrie::Persistence::Solr::Queries::FindOrderedReferencesQuery.new(resource: resource, property: property, connection: connection, resource_factory: resource_factory).run
        else
          Valkyrie::Persistence::Solr::Queries::FindReferencesQuery.new(resource: resource, property: property, connection: connection, resource_factory: resource_factory).run
        end
      return result unless model
      result.select { |obj| obj.is_a?(model) }
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_inverse_references_by)
    def find_inverse_references_by(resource: nil, id: nil, property:, model: nil)
      raise ArgumentError, "Provide resource or id" unless resource || id
      ensure_persisted(resource) if resource
      id ||= resource.id
      result = Valkyrie::Persistence::Solr::Queries::FindInverseReferencesQuery.new(id: id, property: property, connection: connection, resource_factory: resource_factory).run
      return result unless model
      result.select { |obj| obj.is_a?(model) }
    end

    # (see Valkyrie::Persistence::Memory::QueryService#custom_queries)
    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end

    private

    # (see Valkyrie::Persistence::Memory::QueryService#validate_id)
    def validate_id(id)
      raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID
    end

    # (see Valkyrie::Persistence::Memory::QueryService#ensure_persisted)
    def ensure_persisted(resource)
      raise ArgumentError, 'resource is not saved' unless resource.persisted?
    end

    # (see Valkyrie::Persistence::Memory::QueryService#ordered_property?)
    def ordered_property?(resource:, property:)
      resource.ordered_attribute?(property)
    end
  end
end
