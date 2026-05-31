# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Responsible for returning a single resource identified by an ID.
  class FindByAlternateIdentifierQuery
    attr_reader :connection, :resource_factory
    attr_writer :alternate_identifier

    # @param [Valkyrie::ID] alternate_identifier
    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    def initialize(alternate_identifier, connection:, resource_factory:)
      @alternate_identifier = alternate_identifier
      @connection = connection
      @resource_factory = resource_factory
    end

    # Constructs a Valkyrie Resource found using the alternate ID
    # @raise [Valkyrie::Persistence::ObjectNotFoundError]
    # @return [Valkyrie::Resource]
    def run
      raise ::Valkyrie::Persistence::ObjectNotFoundError unless resource
      resource_factory.to_resource(object: resource)
    end

    # Retrieve the string value for the alternate ID
    # @return [String]
    def alternate_identifier
      @alternate_identifier.to_s
    end

    # Query Solr for for the first document with the alternate ID in a field
    # @note the field used here is alternate_ids_ssim and the value is prefixed by "id-"
    # @return [Hash]
    def resource
      @resource ||= connection.get("select", params: { q: "alternate_ids_ssim:\"id-#{alternate_identifier}\"", fl: "*", rows: 1 })["response"]["docs"].first
    end
  end
end
