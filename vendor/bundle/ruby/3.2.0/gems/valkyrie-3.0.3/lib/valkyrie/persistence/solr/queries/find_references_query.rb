# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Responsible for efficently returning all {Valkyrie::Resource}s which are referenced in
  # a given {Valkyrie::Resource}'s property.
  class FindReferencesQuery
    attr_reader :resource, :property, :connection, :resource_factory

    # @param [Valkyrie::Resource] resource
    # @param [String] property resource property referencing other resources
    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    def initialize(resource:, property:, connection:, resource_factory:)
      @resource = resource
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
        params = { q: query, defType: 'lucene' }
        result = connection.paginate(docs.next_page, docs.per_page, 'select', params: params)
        docs = result.fetch('response').fetch('docs')
        docs.each do |doc|
          yield resource_factory.to_resource(object: doc)
        end
      end
    end

    # Generate the Solr join query using the id_ssi field
    # @see https://lucene.apache.org/solr/guide/other-parsers.html#join-query-parser
    # @return [String]
    def query
      "{!join from=#{property}_ssim to=join_id_ssi}id:#{id}"
    end

    # Retrieve the string value for the ID
    # @return [String]
    def id
      resource.id.to_s
    end
  end
end
