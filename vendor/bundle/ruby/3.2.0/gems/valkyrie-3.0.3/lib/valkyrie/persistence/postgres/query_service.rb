# frozen_string_literal: true
module Valkyrie::Persistence::Postgres
  # Query Service for the Postgres Metadata Adapter
  #
  # Most queries are delegated through to the ActiveRecord model
  # {Valkyrie::Persistence::Postgres::ORM::Resource}
  #
  # @see Valkyrie::Persistence::Postgres::MetadataAdapter
  class QueryService
    attr_reader :resource_factory, :adapter
    delegate :orm_class, to: :resource_factory

    # @param [ResourceFactory] resource_factory
    def initialize(adapter:, resource_factory:)
      @resource_factory = resource_factory
      @adapter = adapter
    end

    # Retrieve all records for the resource and construct Valkyrie Resources
    #   for each record
    # @return [Array<Valkyrie::Resource>]
    def find_all
      orm_class.find_each.lazy.map do |orm_object|
        resource_factory.to_resource(object: orm_object)
      end
    end

    # Retrieve all records for a specific resource type and construct Valkyrie
    #   Resources for each record
    # @param [Class] model
    # @return [Array<Valkyrie::Resource>]
    def find_all_of_model(model:)
      orm_class.where(internal_resource: model.to_s).find_each.lazy.map do |orm_object|
        resource_factory.to_resource(object: orm_object)
      end
    end

    # Count all records for a specific resource type
    # @param [Class] model
    # @return integer
    def count_all_of_model(model:)
      orm_class.where(internal_resource: model.to_s).count
    end

    # Find a record using a Valkyrie ID, and map it to a Valkyrie Resource
    # @param [Valkyrie::ID, String] id
    # @return [Valkyrie::Resource]
    # @raise [Valkyrie::Persistence::ObjectNotFoundError]
    def find_by(id:)
      id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
      validate_id(id)
      resource_factory.to_resource(object: orm_class.find(id.to_s))
    rescue ActiveRecord::RecordNotFound
      raise Valkyrie::Persistence::ObjectNotFoundError
    end

    # Find and a record using a Valkyrie ID for an alternate ID, and construct
    #   a Valkyrie Resource
    # @param [Valkyrie::ID] alternate_identifier
    # @return [Valkyrie::Resource]
    def find_by_alternate_identifier(alternate_identifier:)
      alternate_identifier = Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
      validate_id(alternate_identifier)
      internal_array = "{\"alternate_ids\": [{\"id\": \"#{alternate_identifier}\"}]}"
      run_query(find_inverse_references_query, internal_array).first || raise(Valkyrie::Persistence::ObjectNotFoundError)
    end

    # Find records using a set of Valkyrie IDs, and map each to Valkyrie
    #   Resources
    # @param [Array<Valkyrie::ID>] ids
    # @return [Array<Valkyrie::Resource>]
    def find_many_by_ids(ids:)
      ids.map! do |id|
        id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
        validate_id(id)
        id.to_s
      end

      orm_class.where(id: ids).map do |orm_resource|
        resource_factory.to_resource(object: orm_resource)
      end
    end

    # Find all member resources for a given Valkyrie Resource
    # @param [Valkyrie::Resource] resource
    # @param [Class] model
    # @return [Array<Valkyrie::Resource>]
    def find_members(resource:, model: nil)
      return [] if resource.id.blank?
      if model
        run_query(find_members_with_type_query, resource.id.to_s, model.to_s)
      else
        run_query(find_members_query, resource.id.to_s)
      end
    end

    # Find all parent resources for a given Valkyrie Resource
    # @param [Valkyrie::Resource] resource
    # @return [Array<Valkyrie::Resource>]
    def find_parents(resource:)
      find_inverse_references_by(resource: resource, property: :member_ids)
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_references_by)
    def find_references_by(resource:, property:, model: nil)
      return [] if resource.id.blank? || resource[property].blank?
      # only return ordered if needed to avoid performance penalties
      if ordered_property?(resource: resource, property: property)
        find_ordered_references_by(resource: resource, property: property, model: model)
      else
        find_unordered_references_by(resource: resource, property: property, model: model)
      end
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_inverse_references_by)
    def find_inverse_references_by(resource: nil, id: nil, property:, model: nil)
      raise ArgumentError, "Provide resource or id" unless resource || id
      ensure_persisted(resource) if resource
      id ||= resource.id
      internal_array = "{\"#{property}\": [{\"id\": \"#{id}\"}]}"
      if model
        run_query(find_inverse_references_with_type_query, internal_array, model)
      else
        run_query(find_inverse_references_query, internal_array)
      end
    end

    # Execute a query in SQL for resource records and map them to Valkyrie
    #   Resources
    # @param [String] query
    # @return [Array<Valkyrie::Resource>]
    def run_query(query, *args)
      orm_class.find_by_sql(([query] + args)).lazy.map do |object|
        resource_factory.to_resource(object: object)
      end
    end

    # Generate the SQL query for retrieving member resources in PostgreSQL using a
    #   resource ID as an argument.
    # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
    # @note this uses a CROSS JOIN for all combinations of member IDs with the
    #   IDs of their parents
    # @see https://www.postgresql.org/docs/current/static/queries-table-expressions.html#QUERIES-FROM
    # This also uses JSON functions in order to retrieve JSON property values
    # @see https://www.postgresql.org/docs/current/static/functions-json.html
    # @return [String]
    def find_members_query
      <<-SQL
        SELECT member.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->'member_ids') WITH ORDINALITY AS b(member, member_pos)
        JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
        ORDER BY b.member_pos
      SQL
    end

    # Generate the SQL query for retrieving member resources in PostgreSQL using a
    #   resource ID and resource type as arguments.
    # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
    # @note this uses a CROSS JOIN for all combinations of member IDs with the
    #   IDs of their parents
    # @see https://www.postgresql.org/docs/current/static/queries-table-expressions.html#QUERIES-FROM
    # This also uses JSON functions in order to retrieve JSON property values
    # @see https://www.postgresql.org/docs/current/static/functions-json.html
    # @return [String]
    def find_members_with_type_query
      <<-SQL
        SELECT member.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->'member_ids') WITH ORDINALITY AS b(member, member_pos)
        JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
        AND member.internal_resource = ?
        ORDER BY b.member_pos
      SQL
    end

    # Generate the SQL query for retrieving member resources in PostgreSQL using a
    #   JSON object literal as an argument (e. g. { "alternate_ids": [{"id": "d6e88f80-41b3-4dbf-a2a0-cd79e20f6d10"}] }).
    # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
    # This uses JSON functions in order to retrieve JSON property values
    # @see https://www.postgresql.org/docs/current/static/functions-json.html
    # @return [String]
    def find_inverse_references_query
      <<-SQL
        SELECT * FROM orm_resources WHERE
        metadata @> ?
      SQL
    end

    # Generate the SQL query for retrieving member resources in PostgreSQL using a
    #   JSON object literal (e. g. { "alternate_ids": [{"id": "d6e88f80-41b3-4dbf-a2a0-cd79e20f6d10"}] }).
    #   and resource type as arguments
    # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
    # This uses JSON functions in order to retrieve JSON property values
    # @see https://www.postgresql.org/docs/current/static/functions-json.html
    # @return [String]
    def find_inverse_references_with_type_query
      <<-SQL
        SELECT * FROM orm_resources WHERE
        metadata @> ?
        AND internal_resource = ?
      SQL
    end

    # Generate the SQL query for retrieving member resources in PostgreSQL using a
    #   JSON object literal and resource ID as arguments.
    # @see https://guides.rubyonrails.org/active_record_querying.html#array-conditions
    # @note this uses a CROSS JOIN for all combinations of member IDs with the
    #   IDs of their parents
    # @see https://www.postgresql.org/docs/current/static/queries-table-expressions.html#QUERIES-FROM
    # This also uses JSON functions in order to retrieve JSON property values
    # @see https://www.postgresql.org/docs/current/static/functions-json.html
    # @return [String]
    def find_references_query
      <<-SQL
        SELECT DISTINCT member.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->?) AS b(member)
        JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
      SQL
    end

    def find_references_with_type_query
      <<-SQL
        SELECT DISTINCT member.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->?) AS b(member)
        JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ? AND member.internal_resource = ?
      SQL
    end

    def find_ordered_references_query
      <<-SQL
        SELECT member.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->?) WITH ORDINALITY AS b(member, member_pos)
        JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ?
        ORDER BY b.member_pos
      SQL
    end

    def find_ordered_references_with_type_query
      <<-SQL
        SELECT member.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->?) WITH ORDINALITY AS b(member, member_pos)
        JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = ? AND member.internal_resource = ?
        ORDER BY b.member_pos
      SQL
    end

    # Constructs a Valkyrie::Persistence::CustomQueryContainer using this query service
    # @return [Valkyrie::Persistence::CustomQueryContainer]
    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end

    private

    def find_ordered_references_by(resource:, property:, model: nil)
      if model
        run_query(find_ordered_references_with_type_query, property, resource.id.to_s, model)
      else
        run_query(find_ordered_references_query, property, resource.id.to_s)
      end
    end

    def find_unordered_references_by(resource:, property:, model: nil)
      if model
        run_query(find_references_with_type_query, property, resource.id.to_s, model)
      else
        run_query(find_references_query, property, resource.id.to_s)
      end
    end

    # Determines whether or not an Object is a Valkyrie ID
    # @param [Object] id
    # @raise [ArgumentError]
    def validate_id(id)
      raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID
    end

    # Determines whether or not a resource has been persisted
    # @param [Object] resource
    # @raise [ArgumentError]
    def ensure_persisted(resource)
      raise ArgumentError, 'resource is not saved' unless resource.persisted?
    end

    # Accesses the data type in PostgreSQL used for the primary key
    # (For example, a UUID)
    # @see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaCache.html#method-i-columns_hash
    # @return [Symbol]
    def id_type
      @id_type ||= orm_class.columns_hash["id"].type
    end

    def ordered_property?(resource:, property:)
      resource.ordered_attribute?(property)
    end
  end
end
