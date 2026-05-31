module LD::Patch::Algebra

  ##
  # The LD Patch `patch` operator.
  #
  # Transactionally iterates over all operands building bindings along the way
  class Patch < SPARQL::Algebra::Operator
    include SPARQL::Algebra::Update

    NAME = :patch

    ##
    # Executes this upate on the given `transactable` graph or repository.
    #
    # @param  [RDF::Transactable] graph
    #   the graph to update.
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @return [RDF::Transactable]
    #   Returns graph.
    # @raise [Error]
    #   If any error is caught along the way, and rolls back the transaction
    def execute(graph, options = {})
      debug(options) {"Delete"}

      if graph.respond_to?(:transaction)
        graph.transaction(mutable: true) do |tx|
          operands.inject(RDF::Query::Solutions.new([RDF::Query::Solution.new])) do |bindings, op|
            # Invoke operand using bindings from prvious operation
            op.execute(tx, options.merge(bindings: bindings))
          end
        end
      else
        operands.inject(RDF::Query::Solutions.new([RDF::Query::Solution.new])) do |bindings, op|
          # Invoke operand using bindings from prvious operation
          op.execute(graph, options.merge(bindings: bindings))
        end
      end
    end
  end
end