require 'rdf'

module RDF
  ##
  # A Merged graph.
  #
  # Implements a merged graph, containing statements from one or more source graphs. This is done through lazy evaluation of the sources, so that a copy of each source isn't required.
  #
  # This class can also be used to change the context (graph name) of triples from the name used in the source.
  #
  # @example Constructing a merge with arguments
  #   aggregate = RDF::AggregateRepo.new(repo1, repo2)
  #
  # @example Constructing an aggregate with closure
  #   aggregate = RDF::MergeGraph.new do
  #     source graph1, context1
  #     source graph2, context2
  #     name false
  #   end
  #
  # @see https://www.w3.org/TR/rdf11-mt/#dfn-merge
  class MergeGraph
    include RDF::Value
    include RDF::Countable
    include RDF::Enumerable
    include RDF::Queryable

    ##
    # The set of aggregated `queryable` instances included in this aggregate
    #
    # @return [Array<Array<(RDF::Queryable, RDF::Resource)>>]
    attr_reader :sources

    ##
    # Name of this graph, used for setting the context on returned `Statements`.
    #
    # @return [Array<RDF::URI, false>]
    attr_reader :graph_name

    ##
    # Create a new aggregation instance.
    #
    # @param [RDF::Resource] graph_name
    # @param [RDF::Resource] name alias for `graph_name`
    # @yield merger
    # @yieldparam [RDF::MergeGraph] self
    # @yieldreturn [void] ignored
    def initialize(graph_name: nil, name: nil, &block)
      @sources = []
      @graph_name = graph_name || name

      if block_given?
        case block.arity
        when 1 then block.call(self)
        else instance_eval(&block)
        end
      end
    end


    ##
    # Returns `true` to indicate that this is a graph.
    #
    # @return [Boolean]
    def graph?
      true
    end

    ##
    # Returns `true` if this is a named graph.
    #
    # @return [Boolean]
    # @note The next release, graphs will not be named, this will return false
    def named?
      !unnamed?
    end

    ##
    # Returns `true` if this is a unnamed graph.
    #
    # @return [Boolean]
    # @note The next release, graphs will not be named, this will return true
    def unnamed?
      @graph_name.nil?
    end

    ##
    # MergeGraph is writable if any source is writable. Updates go to the last writable source.
    #
    # @return [Boolean]
    def writable?
      sources.any? {|(source, ctx)| source.writable?}
    end

    ##
    # Add a queryable to the set of constituent queryable instances
    #
    # @param [RDF::Queryable] queryable
    # @param [RDF::Resource] graph_name
    # @return [RDF::MergeGraph] self
    def source(queryable, graph_name)
      @sources << [queryable, graph_name]
      self
    end
    alias_method :add, :source

    ##
    # Set the graph_name for statements in this graph
    #
    # @param [RDF::Resource, false] name
    # @return [RDF::MergeGraph] self
    def name(name)
      @graph_name = name
      self
    end

    # Repository overrides

    ##
    # @private
    # @see RDF::Durable#durable?
    def durable?
      sources.all? {|(source, ctx)| source.durable?}
    end

    ##
    # @private
    # @see RDF::Countable#empty?
    def empty?
      count == 0
    end

    ##
    # @private
    # @see RDF::Countable#count
    def count
      each_statement.to_a.length
    end

    ##
    # @private
    # @see RDF::Enumerable#has_statement?
    def has_statement?(statement)
      sources.any? do |(source, ctx)|
        statement = statement.dup
        statement.graph_name = ctx
        source.has_statement?(statement)
      end
    end

    ##
    # @see RDF::Enumerable#each_statement
    def each(&block)
      return enum_for(:each) unless block_given?

      # Add everything to a new graph for de-duplication
      tmp = RDF::Graph.new(graph_name: @graph_name, data: RDF::Repository.new)
      sources.each do |(source, gn)|
        tmp << RDF::Graph.new(graph_name: gn || nil, data: source)
      end
      tmp.each(&block)
    end

    ##
    # @private
    # @see RDF::Enumerable#has_graph?
    def has_graph?(value)
      @graph_name == value
    end

    ##
    # Iterate over each graph, in order, finding named graphs from the most recently added `source`.
    #
    # @see RDF::Enumerable#each_graph
    def each_graph(&block)
      if block_given?
        yield self
      end
      enum_graph
    end

  protected

    ##
    # @private
    # @see RDF::Queryable#query_pattern
    def query_pattern(pattern, **options, &block)
      return enum_for(:query_pattern, pattern, **options) unless block_given?
      pattern = pattern.dup
      sources.each do |(source, gn)|
        pattern.graph_name = gn
        source.send(:query_pattern, pattern, **options, &block)
      end
    end
  end
end
