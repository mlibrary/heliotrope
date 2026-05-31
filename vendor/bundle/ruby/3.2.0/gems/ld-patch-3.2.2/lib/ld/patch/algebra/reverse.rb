module LD::Patch::Algebra

  ##
  # The LD Patch `reverse` operator
  #
  # Finds all the terms which are the subject of triples where the `operand` is the predicate and input terms are objects.
  #
  # @example
  #     (reverse :p)
  #
  #   Queries `queryable` for subjects where input terms are objects and the predicate is `:p`, by executing the `reverse` operand using input terms to get a set of output terms.
  class Reverse < SPARQL::Algebra::Operator::Unary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Evaluatable

    NAME = :reverse

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
      debug(options) {"Reverse"}
      op = operand(0)
      terms = Array(options.fetch(:terms))

      results = terms.map do |object|
        queryable.query({object: object, predicate: op}).map(&:subject)
      end.flatten

      RDF::Query::Solutions.new(results.map {|t| RDF::Query::Solution.new(path: t)})
    end
  end
end