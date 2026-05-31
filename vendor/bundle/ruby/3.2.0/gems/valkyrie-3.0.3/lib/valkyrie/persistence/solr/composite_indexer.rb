# frozen_string_literal: true
module Valkyrie::Persistence::Solr
  # Composite object to make multiple custom indexers act like a single one, so
  # that upstream code doesn't have to know how to iterate over indexers.
  #
  # @see https://en.wikipedia.org/wiki/Composite_pattern
  class CompositeIndexer
    attr_reader :indexers

    # @param [Array<Object>] indexers
    def initialize(*indexers)
      @indexers = indexers
    end

    # Construct a new Instance object
    # @param [Valkyrie::Resource] resource
    def new(resource:)
      Instance.new(indexers, resource: resource)
    end

    # Class providing the common method interface for the Indexer
    class Instance
      attr_reader :indexers, :resource

      # @param [Array<Object>] indexers
      # @param [Valkyrie::Resource] resource
      def initialize(indexers, resource:)
        @resource = resource
        @indexers = indexers.map { |i| i.new(resource: resource) }
      end

      # Generate the Solr Documents from the indexers
      # @return [Array<Hash>]
      def to_solr
        indexers.map(&:to_solr).inject({}, &:merge)
      end
    end
  end
end
