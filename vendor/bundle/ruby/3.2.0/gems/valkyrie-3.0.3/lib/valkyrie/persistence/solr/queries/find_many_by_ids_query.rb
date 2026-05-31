# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  class FindManyByIdsQuery
    attr_reader :connection, :resource_factory
    attr_accessor :ids

    # @param [Array<Valkyrie::ID>] ids
    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    def initialize(ids, connection:, resource_factory:)
      @ids = ids
      @connection = connection
      @resource_factory = resource_factory
    end

    # Iterate over each Solr Document and convert each Document into a Valkyrie Resource
    # @return [Array<Valkyrie::Resource>]
    def run
      resources.map { |solr_resource| resource_factory.to_resource(object: solr_resource) }
    end

    # Query Solr for for all documents with the IDs in the requested field
    # @note this uses the "OR" operator for concatenating IDs and requests 1000000000 Documents
    # @return [Array<Hash>]
    def resources
      id_query = ids.map { |id| "\"#{id}\"" }.join(' OR ')
      @resources ||= connection.get("select", params: { q: "id:(#{id_query})", fl: "*", defType: 'lucene', rows: 1_000_000_000 })["response"]["docs"]
    end
  end
end
