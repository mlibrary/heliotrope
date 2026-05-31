# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Responsible for efficiently returning all objects in the solr repository as
  # {Valkyrie::Resource}s
  class FindAllQuery
    attr_reader :connection, :resource_factory, :model

    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    # @param [Class] model
    def initialize(connection:, resource_factory:, model: nil)
      @connection = connection
      @resource_factory = resource_factory
      @model = model
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

    # Queries without making Resrouces and returns the RSolr page_total value
    # @return [Integer]
    def count
      connection.get("select", params: { q: query })["response"]["numFound"].to_s.to_i
    end

    # Generates the Solr query for retrieving all Documents in the index
    # If a model is specified for the query, it is scoped to that Valkyrie resource type
    # @return [String]
    def query
      if !model
        "*:*"
      else
        "#{Valkyrie::Persistence::Solr::Queries::MODEL}:#{model}"
      end
    end
  end
end
