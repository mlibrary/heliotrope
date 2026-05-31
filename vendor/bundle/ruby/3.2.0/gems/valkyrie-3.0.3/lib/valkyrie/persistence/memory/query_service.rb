# frozen_string_literal: true
module Valkyrie::Persistence::Memory
  # Query Service for the memory metadata adapter.
  # @see Valkyrie::Persistence::Memory
  # @note Documentation for Query Services in general is maintained here.
  class QueryService
    attr_reader :adapter, :query_handlers
    delegate :cache, to: :adapter

    # @param adapter [Valkyrie::Persistence::Memory::MetadataAdapter] The adapter which
    #   has the cache to query.
    # @note Many query service methods are part of Valkyrie's public API, but instantiation itself is not
    def initialize(adapter:)
      @adapter = adapter
      @query_handlers = []
    end

    # Get a single resource by ID.
    # @param id [Valkyrie::ID] The ID to query for.
    # @raise [Valkyrie::Persistence::ObjectNotFoundError] Raised when the ID
    #   isn't in the persistence backend.
    # @raise [ArgumentError] Raised when ID is not a String or a Valkyrie::ID
    # @return [Valkyrie::Resource] The object being searched for.
    def find_by(id:)
      id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
      validate_id(id)
      cache[id] || raise(::Valkyrie::Persistence::ObjectNotFoundError)
    end

    # Get a single resource by `alternate_identifier`. Alternate identifiers are identifiers (like NOIDs,
    # DOIs, ARKs, etc.) that are not the system-generated ID, but might be used to identify a resource in an
    # application (e.g., to make shorter URLs).
    # @param alternate_identifier [Valkyrie::ID] The alternate identifier to query for.
    # @raise [Valkyrie::Persistence::ObjectNotFoundError] Raised when the alternate identifier
    #   isn't in the persistence backend.
    # @raise [ArgumentError] Raised when alternate identifier is not a String or a Valkyrie::ID
    # @return [Valkyrie::Resource] The object being searched for.
    def find_by_alternate_identifier(alternate_identifier:)
      alternate_identifier = Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
      validate_id(alternate_identifier)
      cache.select do |_key, resource|
        next unless resource[:alternate_ids]
        resource[:alternate_ids].include?(alternate_identifier)
      end.values.first || raise(::Valkyrie::Persistence::ObjectNotFoundError)
    end

    # Get a batch of resources by ID.
    # @param ids [Array<Valkyrie::ID, String>] The IDs to query for.
    # @raise [ArgumentError] Raised when any ID is not a String or a Valkyrie::ID
    # @return [Array<Valkyrie::Resource>] All requested objects that were found
    def find_many_by_ids(ids:)
      ids = ids.uniq
      ids.map do |id|
        find_by(id: id)
      rescue ::Valkyrie::Persistence::ObjectNotFoundError
        nil
      end.reject(&:nil?)
    end

    # Get all objects.
    # @return [Array<Valkyrie::Resource>] All objects in the persistence backend.
    def find_all
      cache.values
    end

    # Get all objects of a given model.
    # @param model [Class] Class to query for.
    # @return [Array<Valkyrie::Resource>] All objects in the persistence backend
    #   with the given class.
    def find_all_of_model(model:)
      cache.values.select do |obj|
        obj.is_a?(model)
      end
    end

    # Count all objects of a given model.
    # @param model [Class] Class to query for.
    # @return integer. Count objects in the persistence backend
    #   with the given class.
    def count_all_of_model(model:)
      cache.values.count { |obj| obj.is_a?(model) }
    end

    # Get all members of a given resource.
    # @param resource [Valkyrie::Resource] Model whose members are being searched for.
    # @param model [Class] Filter results to include only instances of this model. (optional)
    # @return [Array<Valkyrie::Resource>] child objects of type `model` referenced by
    #   `resource`'s `member_ids` method. Returned in order.
    def find_members(resource:, model: nil)
      result = member_ids(resource: resource).map do |id|
        find_by(id: id)
      end
      return result unless model
      result.select { |obj| obj.is_a?(model) }
    end

    # Get all resources referenced from a resource with a given property.
    # @param resource [Valkyrie::Resource] Model whose property is being searched.
    # @param property [Symbol] Property which, on the `resource`, contains {Valkyrie::ID}s which are
    #   to be de-referenced.
    # @param model [Class] Filter results to include only instances of this model. (optional)
    # @return [Array<Valkyrie::Resource>] All objects which are referenced by the
    #   `property` property on `resource`. Not necessarily in order.
    def find_references_by(resource:, property:, model: nil)
      refs = Array.wrap(resource[property]).map do |id|
        find_by(id: id)
             rescue ::Valkyrie::Persistence::ObjectNotFoundError
               nil
      end.reject(&:nil?)
      refs.uniq! unless ordered_property?(resource: resource, property: property)
      return refs unless model
      refs.select { |obj| obj.is_a?(model) }
    end

    # Get all resources which link to a resource with a given property.
    # @param resource [Valkyrie::Resource] The resource which is being referenced by
    #   other resources. Requires either resource or id parameter to be specified.
    # @param id [Valkyrie::ID] ID of the resource which is being reference by other
    #   resources. Requires either resource or id parameter to be specified.
    # @param property [Symbol] The property which, on other resources, is
    #   referencing the given `resource`
    # @param model [Class] Filter results to include only instances of this model. (optional)
    # @raise [ArgumentError] Raised when the ID is not in the persistence backend.
    # @return [Array<Valkyrie::Resource>] All resources in the persistence backend
    #   which have the ID of the given `resource` in their `property` property. Not
    #   in order.
    def find_inverse_references_by(resource: nil, id: nil, property:, model: nil)
      raise ArgumentError, "Provide resource or id" unless resource || id
      ensure_persisted(resource) if resource
      id ||= resource.id
      result = find_all.select do |obj|
        Array.wrap(obj[property]).include?(id)
      end
      return result unless model
      result.select { |obj| obj.is_a?(model) }
    end

    # Find all parents of a given resource.
    # @param resource [Valkyrie::Resource] The resource whose parents are being searched
    #   for.
    # @return [Array<Valkyrie::Resource>] All resources which are parents of the given
    #   `resource`. This means the resource's `id` appears in their `member_ids`
    #   array.
    def find_parents(resource:)
      cache.values.select do |record|
        member_ids(resource: record).include?(resource.id)
      end
    end

    # Get the set of custom queries configured for this query service.
    # @return [Valkyrie::Persistence::CustomQueryContainer] Container of custom queries
    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end

    private

    # @return [Array<Valkyrie::ID>] a list of the identifiers of the member objects
    def member_ids(resource:)
      return [] unless resource.respond_to? :member_ids
      resource.member_ids || []
    end

    # Determine whether or not a value is a Valkyrie ID
    # @param [Object] id
    # @return [Boolean]
    def validate_id(id)
      raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID
    end

    # Ensure that a given Valkyrie Resource has been persisted
    # @param [Valkyrie::Resource] resource
    def ensure_persisted(resource)
      raise ArgumentError, 'resource is not saved' unless resource.persisted?
    end

    def ordered_property?(resource:, property:)
      resource.ordered_attribute?(property)
    end
  end
end
