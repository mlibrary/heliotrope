module LD::Patch::Algebra

  ##
  # The LD Patch `index` operator.
  #
  # Presuming that the input term identifies an rdf:List, returns the list element indexted by the single operand, or an empty solution set
  class Index < SPARQL::Algebra::Operator::Unary
    include SPARQL::Algebra::Query

    NAME = :index

    ##
    # Executes this upate on the given `writable` graph or repository.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to write
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Array<RDF::Term>] starting terms
    # @return [RDF::Query::Solutions] solutions with `:term` mapping
    def execute(queryable, options = {})
      debug(options) {"Index"}
      terms = Array(options.fetch(:terms))
      index = operand(0)

      results = terms.map do |term|
        list = RDF::List.new(subject: term, graph: queryable)
        list.at(index.to_i)
      end.flatten

      RDF::Query::Solutions.new(results.map {|t| RDF::Query::Solution.new(path: t)})
    end
  end
end