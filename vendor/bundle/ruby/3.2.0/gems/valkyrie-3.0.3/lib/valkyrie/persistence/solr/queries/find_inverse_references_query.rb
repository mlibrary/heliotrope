# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Responsible for efficiently returning all {Valkyrie::Resource}s which
  # reference a {Valkyrie::Resource} in a given property.
  class FindInverseReferencesQuery
    attr_reader :id, :property, :connection, :resource_factory

    # @param [Valkyrie::Resource] resource
    # @param [String] property
    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    def initialize(resource: nil, id: nil, property:, connection:, resource_factory:)
      @id = id ? id : resource.id
      @property = property
      @connection = connection
      @resource_factory = resource_factory
    end

    # Iterate over each Solr Document and convert each Document into a Valkyrie Resource
    # @return [Array<Valkyrie::Resource>]
    def run
      enum_for(:each)
    end

    # Queries for all Documents in the Solr index
    # For each Document, it yields the Valkyrie Resource which was converted from it
    # @yield [Valkyrie::Resource]
    def each
      docs = DefaultPaginator.new
      while docs.has_next?
        docs = connection.paginate(docs.next_page, docs.per_page, "select", params: { q: query })["response"]["docs"]
        docs.each do |doc|
          yield resource_factory.to_resource(object: doc)
        end
      end
    end

    # Query Solr for for all documents with the ID in the requested field
    # @note the field used here is a _ssim dynamic field and the value is prefixed by "id-"
    # @return [Hash]
    def query
      "#{property}_ssim:id-#{id}"
    end
  end
end
