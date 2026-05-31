# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Responsible for returning a single resource identified by an ID.
  class FindByIdQuery
    attr_reader :connection, :resource_factory
    attr_writer :id

    # @param [Valkyrie::ID] id
    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    def initialize(id, connection:, resource_factory:)
      @id = id
      @connection = connection
      @resource_factory = resource_factory
    end

    # Constructs a Valkyrie Resource found using the ID
    # @raise [Valkyrie::Persistence::ObjectNotFoundError]
    # @return [Valkyrie::Resource]
    def run
      raise ::Valkyrie::Persistence::ObjectNotFoundError unless resource
      resource_factory.to_resource(object: resource)
    end

    # Retrieve the string value for the ID
    # @return [String]
    def id
      @id.to_s
    end

    # Query Solr for for the first document with the ID in a field
    # @return [Hash]
    def resource
      @resource ||= connection.get("select", params: { q: "id:\"#{id}\"", fl: "*", rows: 1 })["response"]["docs"].first
    end
  end
end
