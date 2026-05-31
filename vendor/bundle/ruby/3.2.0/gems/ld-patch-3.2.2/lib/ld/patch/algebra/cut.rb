module LD::Patch::Algebra

  ##
  # The LD Patch `cut` operator.
  #
  # The Cut operation is recursively remove triples from some starting node.
  #
  # @example
  #   (cut ?a)
  #
  class Cut < SPARQL::Algebra::Operator::Unary
    include SPARQL::Algebra::Update
    include SPARQL::Algebra::Evaluatable

    NAME = :cut

    ##
    # Executes this upate on the given `writable` graph or repository.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to write
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @return [RDF::Query::Solutions] A single solution including passed bindings with `var` bound to the solution.
    # @raise [IOError]
    #   If no triples are identified, or the operand is an unbound variable or the operand is an unbound variable.
    # @see    http://www.w3.org/TR/sparql11-update/
    def execute(queryable, options = {})
      debug(options) {"Cut"}
      bindings = options.fetch(:bindings)
      solution = bindings.first
      var = operand(0)

      # Bind variable
      raise LD::Patch::Error.new("Operand uses unbound variable #{var.inspect}", code: 400) unless solution.bound?(var)
      var = solution[var]

      cut_count = 0
      # Get triples to delete using consice bounded description
      queryable.concise_bounded_description(var) do |statement|
        queryable.delete(statement)
        cut_count += 1
      end

      # Also delete triples having var in the object position
      queryable.query({object: var}).each do |statement|
        queryable.delete(statement)
        cut_count += 1
      end

      raise LD::Patch::Error, "Cut removed no triples" unless cut_count > 0

      bindings
    end
  end
end