module LD::Patch::Algebra

  ##
  # The LD Patch `delete` operator (incuding `deleteExisting`).
  #
  # The Add operation is used to delete triples from the target graph with or without checking to see if the exist already.
  #
  # @example
  #   (add ((<a> <b> <c>)))
  #
  class Delete < SPARQL::Algebra::Operator::Unary
    include SPARQL::Algebra::Update
    include SPARQL::Algebra::Evaluatable

    NAME = :delete

    ##
    # Executes this upate on the given `writable` graph or repository.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to write
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Boolean] :existing
    #   Specifies that triples must already exist in the target graph
    # @return [RDF::Query::Solutions] A single solution including passed bindings with `var` bound to the solution.
    # @raise [Error]
    #   If `existing` is specified, and any triple is not found in the traget graph, or if unbound variables are used.
    # @see    http://www.w3.org/TR/sparql11-update/
    def execute(queryable, options = {})
      debug(options) {"Delete"}
      bindings = options.fetch(:bindings)
      solution = bindings.first

      # Bind variables to triples
      triples = operand(0).dup.replace_vars! do |var|
        case var
        when RDF::Query::Pattern
          s = var.bind(solution)
          raise LD::Patch::Error.new("Operand uses unbound pattern #{var.inspect}", code: 400) if s.variable?
          s
        when RDF::Query::Variable
          raise LD::Patch::Error.new("Operand uses unbound variable #{var.inspect}", code: 400) unless solution.bound?(var)
          solution[var]
        end
      end

      # If `:new` is specified, verify that no triple in triples exists in queryable
      if @options[:existing]
        triples.each do |triple|
          raise LD::Patch::Error, "Target graph does not contain triple #{triple.to_ntriples}" unless queryable.has_statement?(triple)
        end
      end

      queryable.delete(*triples)
      bindings
    end
  end
end