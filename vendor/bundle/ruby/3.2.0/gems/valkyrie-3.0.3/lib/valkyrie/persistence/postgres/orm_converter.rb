# frozen_string_literal: true
module Valkyrie::Persistence::Postgres
  # Responsible for converting a
  # {Valkyrie::Persistence::Postgres::ORM::Resource} to a {Valkyrie::Resource}
  class ORMConverter
    attr_reader :orm_object, :resource_factory

    # @param [ORM::Resource] orm_object
    # @param [ResourceFactory] resource_factory
    def initialize(orm_object, resource_factory:)
      @orm_object = orm_object
      @resource_factory = resource_factory
    end

    # Create a new instance of the class described in attributes[:internal_resource]
    # and send it all the attributes that @orm_object has
    # @return [Valkyrie::Resource]
    def convert!
      @resource ||= resource
    end

    private

    # Construct a new Valkyrie Resource using the attributes retrieved from the database
    # @return [Valkyrie::Resource]
    def resource
      resource_klass.new(
        attributes.merge(
          new_record: false,
          Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK => lock_token
        )
      )
    end

    # Construct the optimistic lock token using the adapter and lock version for the Resource
    # @return [Valkyrie::Persistence::OptimisticLockToken]
    def lock_token
      return lock_token_warning unless orm_object.class.column_names.include?("lock_version")
      @lock_token ||=
        Valkyrie::Persistence::OptimisticLockToken.new(
          adapter_id: resource_factory.adapter_id,
          token: orm_object.lock_version
        )
    end

    # Issue a migration warning for previous releases of Valkyrie which did not support optimistic locking
    def lock_token_warning
      return nil unless resource_klass.optimistic_locking_enabled?
      warn "[MIGRATION REQUIRED] You have loaded a resource from the Postgres adapter with " \
           "optimistic locking enabled, but the necessary migrations have not been run. \n" \
           "Please run `bin/rails valkyrie_engine:install:migrations && bin/rails db:migrate` " \
           "to enable this feature for Postgres."
      nil
    end

    # Retrieve the Class used to construct the Valkyrie Resource
    # @return [Class]
    def resource_klass
      Valkyrie.config.resource_class_resolver.call(internal_resource)
    end

    # Access the String for the Valkyrie Resource type within the attributes
    # @return [String]
    def internal_resource
      attributes[:internal_resource]
    end

    # @return [Hash] Valkyrie-style hash of attributes.
    def attributes
      @attributes ||= orm_object.attributes.merge(rdf_metadata).symbolize_keys
    end

    # Generate a Hash derived from Valkyrie Resource metadata encoded in the RDF
    # @return [Hash]
    def rdf_metadata
      @rdf_metadata ||= RDFMetadata.new(orm_object.metadata).result
    end

    # Responsible for converting `metadata` JSON-B field in
    # {Valkyrie::Persistence::Postgres::ORM::Resource} into an acceptable hash
    # for {Valkyrie::Resource}
    class RDFMetadata < ::Valkyrie::Persistence::Shared::JSONValueMapper
    end
  end
end
