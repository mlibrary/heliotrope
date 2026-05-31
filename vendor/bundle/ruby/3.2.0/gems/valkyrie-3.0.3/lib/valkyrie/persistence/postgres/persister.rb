# frozen_string_literal: true
require 'valkyrie/persistence/postgres/orm'
require 'valkyrie/persistence/postgres/resource_factory'
module Valkyrie::Persistence::Postgres
  # Persister for Postgres MetadataAdapter.
  class Persister
    attr_reader :adapter
    delegate :resource_factory, to: :adapter

    # @param [MetadataAdapter] adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    # Persists a resource within the database
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the persisted/updated resource
    # @raise [Valkyrie::Persistence::StaleObjectError] raised if the resource
    #   was modified in the database between been read into memory and persisted
    def save(resource:, external_resource: false)
      orm_object = resource_factory.from_resource(resource: resource)
      orm_object.transaction do
        if !external_resource && resource.persisted? && !orm_object.persisted?
          raise Valkyrie::Persistence::ObjectNotFoundError, "The object #{resource.id} is previously persisted but not found at save time."
        end
        orm_object.save!
        if resource.id && resource.id.to_s != orm_object.id
          raise Valkyrie::Persistence::UnsupportedDatatype,
                "Postgres' primary key column can not save with the given ID #{resource.id}. " \
                "To avoid this error, set the ID to be nil via `resource.id = nil` before you save it. \n" \
                "Called from #{Gem.location_of_caller.join(':')}"
        end
      end
      resource_factory.to_resource(object: orm_object)
    rescue ActiveRecord::StaleObjectError
      raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process."
    end

    # Persists a set of resources within the database
    # @param [Array<Valkyrie::Resource>] resources
    # @return [Array<Valkyrie::Resource>] the persisted/updated resources
    # @raise [Valkyrie::Persistence::StaleObjectError] raised if the resource
    #   was modified in the database between been read into memory and persisted
    def save_all(resources:)
      resource_factory.orm_class.transaction do
        resources.map do |resource|
          save(resource: resource)
        end
      end
    rescue Valkyrie::Persistence::StaleObjectError
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process."
    end

    # Deletes a resource persisted within the database
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the deleted resource
    def delete(resource:)
      orm_object = resource_factory.from_resource(resource: resource)
      orm_object.delete
      resource
    end

    # Deletes all resources of a specific Valkyrie Resource type persisted in
    #   the database
    def wipe!
      resource_factory.orm_class.delete_all
    end
  end
end
