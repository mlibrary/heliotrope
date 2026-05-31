module LD::Patch::Algebra

  ##
  # The LD Patch `path` operator.
  #
  # The Path creates a closure over path operands querying `queryable` for terms having a relationship with the input `terms` based on each operand. The terms extracted from the first operand are used as inputs for the next operand until a final set of terms is found. These terms are returned as `RDF:Query::Solution` bound the the variable `?path`
  #
  # @example empty path
  #     (path)
  #
  #   Returns input terms
  #
  # @example forward path
  #     (path :p)
  #
  #   Queries `queryable` for objects where the input terms are subjects and the predicate is `:p`
  #
  # @example reverse path
  #     (path (reverse :p))
  #
  #   Queries `queryable` for subjects where input terms are objects and the predicate is `:p`, by executing the `reverse` operand using input terms to get a set of output terms.
  #
  # @example constraint
  #     (path (constraint (path) :c, 1))
  #
  #   Returns the input terms satisfying the constrant.
  #
  # @example chained path elements
  #     (path :p :q (constraint (path) :c, 1))
  #
  #   Maps terms using `(path :p)`, using them as terms for `(path :q)`, then subsets these based on the constraint.
  class Path < SPARQL::Algebra::Operator
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Evaluatable

    NAME = :path

    ##
    # Executes this operator using the given variable `bindings` and a starting term, returning zero or more terms at the end of the path.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @option options [Array<RDF::Term>] starting terms
    # @return [RDF::Query::Solutions] solutions with `:term` mapping
    def execute(queryable, options = {})
      solutions = RDF::Query::Solutions.new

      # Iterate updating terms, then create solutions from matched terms
      operands.inject(Array(options.fetch(:terms))) do |terms, op|
        case op
        when RDF::URI
          terms.map do |subject|
            queryable.query({subject: subject, predicate: op}).map(&:object)
          end.flatten
        when SPARQL::Algebra::Query
          # Get path solutions for each term for op
          op.execute(queryable, **options.merge(terms: terms)).map do |soln|
            soln.path
          end.flatten
        else
          raise NotImplementedError, "Unknown path operand #{op.inspect}"
        end
      end.each do |term|
        solutions << RDF::Query::Solution.new(path: term)
      end
      solutions
    end
  end
end