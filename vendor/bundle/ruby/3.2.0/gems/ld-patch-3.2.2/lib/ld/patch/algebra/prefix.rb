module LD::Patch::Algebra
  ##
  # The LD Patch `prefix` operator.
  #
  # @example
  #   (prefix ((: <http://example/>))
  #     (graph ?g
  #       (bgp (triple ?s ?p ?o))))
  #
  # @see http://www.w3.org/TR/rdf-sparql-query/#QSynIRI
  class Prefix < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Update
    
    NAME = :prefix

    ##
    # Executes this query on the given `queryable` graph or repository.
    # Really a pass-through, as this is a syntactic object used for providing
    # context for URIs.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @yield  [solution]
    #   each matching solution, statement or boolean
    # @yieldparam  [RDF::Statement, RDF::Query::Solution, Boolean] solution
    # @yieldreturn [void] ignored
    # @return [RDF::Query::Solutions]
    #   the resulting solution sequence
    # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    def execute(queryable, options = {}, &block)
      debug(options) {"Prefix"}
      @solutions = queryable.query(operands.last, **options.merge(depth: options[:depth].to_i + 1), &block)
    end
    
    ##
    # Returns an optimized version of this query.
    #
    # If optimize operands, and if the first two operands are both Queries, replace
    # with the unique sum of the query elements
    #
    # @return [Union, RDF::Query] `self`
    def optimize
      operands.last.optimize
    end
  end # Prefix
end
