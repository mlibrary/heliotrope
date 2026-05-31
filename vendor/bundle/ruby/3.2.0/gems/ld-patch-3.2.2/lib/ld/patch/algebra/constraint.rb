module LD::Patch::Algebra

  ##
  # The LD Patch `constraint` operator.
  #
  # A constraint is a query operator which either ensures that there is a single input node ("!" operator) or finds a set of nodes for a given `path`, optionally filtering those nodes with a particular predicate value.
  #
  # @example existence of path solutions
  #     (constraint (path :p))
  #
  #   Maps input terms to output terms using `(path :p)` returning those input terms that have at least a single solution.
  #
  # @example paths with property value
  #     (constraint (path :p) 1)
  #
  #   Maps input terms to output terms using `(path :p)` and filters the input terms where the output term is `1`.
  #
  # @example unique terms
  #
  #     (constraint unique)
  #
  #   Returns the single term from the input terms if there is a single input term.
  class Constraint < SPARQL::Algebra::Operator
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Evaluatable

    NAME = :constraint

    ##
    # If the first operand is :unique
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to write
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Array<RDF::Term>] starting terms
    # @return [RDF::Query::Solutions] solutions with `:term` mapping
    def execute(queryable, options = {})
      debug(options) {"Constraint"}
      terms = Array(options.fetch(:terms))
      op, value = operands

      results = if op == :unique
        terms.length == 1 ? terms : []
      else
        # op is a path, filter input terms based on the presense or absense of output terms. Additionally, if a constraint value is given, output terms must equal that value
        terms.select do |term|
          output_terms = op.execute(queryable, options.merge(terms: [term])).map(&:path)
          output_terms = output_terms.select {|t| t == value} if value
          !output_terms.empty?
        end
      end
      RDF::Query::Solutions.new(results.map {|t| RDF::Query::Solution.new(path: t)})
    end
  end
end