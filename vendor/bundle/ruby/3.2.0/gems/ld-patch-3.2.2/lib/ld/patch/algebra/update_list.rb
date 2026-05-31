module LD::Patch::Algebra

  ##
  # The LD Patch `updateList` operator.
  #
  # The UpdateList operation is used to splice a new list into a subset of an existing list.
  #
  class UpdateList < SPARQL::Algebra::Operator
    include SPARQL::Algebra::Update
    include SPARQL::Algebra::Evaluatable

    NAME = :updateList

    ##
    # Executes this upate on the given `writable` graph or repository.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to write
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @return [RDF::Query::Solutions] A single solution including passed bindings with `var` bound to the solution.
    # @raise [Error]
    #   If the subject and predicate provided to an UpdateList do not have a unique object, or if this object is not a well-formed collection.
    #   If an index in a slice expression is greater than the length of the rdf:List or otherwise out of bound.
    # @see    http://www.w3.org/TR/sparql11-update/
    def execute(queryable, options = {})
      debug(options) {"UpdateList"}
      bindings = options.fetch(:bindings)
      solution = bindings.first
      var_or_iri, predicate, slice1, slice2, collection = operands

      # Bind variables to path
      if var_or_iri.variable?
        raise LD::Patch::Error("Operand uses unbound variable #{var_or_iri.inspect}", code: 400) unless solution.bound?(var_or_iri)
        var_or_iri = solution[var_or_iri]
      end

      list_heads = queryable.query({subject: var_or_iri, predicate: predicate}).map {|s| s.object}

      raise LD::Patch::Error, "UpdateList ambigious value for #{var_or_iri.to_ntriples} and #{predicate.to_ntriples}" if list_heads.length > 1
      raise LD::Patch::Error, "UpdateList no value found for #{var_or_iri.to_ntriples} and #{predicate.to_ntriples}" if list_heads.empty?
      lh = list_heads.first
      list = RDF::List.new(subject: lh, graph: queryable)
      raise LD::Patch::Error, "Invalid list" unless list.valid?

      start = case
      when slice1.nil? || slice1 == RDF.nil then list.length
      when slice1 < 0 then list.length + slice1.to_i
      else slice1.to_i
      end

      finish = case
      when slice2.nil? || slice2 == RDF.nil then list.length
      when slice2 < 0 then list.length + slice2.to_i
      else slice2.to_i
      end

      raise LD::Patch::Error.new("UpdateList slice indexes out of order #{start}..#{finish}}", code: 400) if finish < start
      
      length = finish - start
      raise LD::Patch::Error, "UpdateList out of bounds #{start}..#{finish}}" if start + length > list.length
      raise LD::Patch::Error, "UpdateList out of bounds #{start}..#{finish}}" if start < 0

      # Uses #[]= logic in RDF::List
      list[start, length] = collection
      new_lh = list.subject

      # If lh was rdf:nil, then we may have a new list head. Similarly, if the list was emptied, we now need to replace the head
      if lh != new_lh
        queryable.delete(RDF::Statement(var_or_iri, predicate, lh))
        queryable.insert(RDF::Statement(var_or_iri, predicate, new_lh))
      end

      bindings
    end
  end
end