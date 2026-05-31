module RDF::N3::Algebra::List
  ##
  # Iff the subject is a list and the object is in that list, then this is true.
  class Member < RDF::N3::Algebra::ListOperator
    NAME = :listMember
    URI = RDF::N3::List.member

    ##
    # Evaluates this operator using the given variable `bindings`.
    # If the last operand is a variable, it creates a solution for each element in the list.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param [RDF::Query::Solutions] solutions
    #   solutions for chained queries
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      RDF::Query::Solutions(solutions.map do |solution|
        list = operand(0).evaluate(solution.bindings, formulae: formulae)
        next unless list
        list = RDF::N3::List.try_list(list, queryable).evaluate(solution.bindings, formulae: formulae)
        object = operand(1).evaluate(solution.bindings, formulae: formulae) || operand(1)
        object = formulae[object].deep_dup if object.node? && formulae.has_key?(object)

        log_debug(NAME) {"list: #{list.to_sxp}, object: #{object.to_sxp}"}
        unless list.list? && list.valid?
          log_error(NAME) {"operand is not a list: #{list.to_sxp}"}
          next
        end

        if object.variable?
          # Bind all list entries to this solution, creates an array of solutions
          list.to_a.map do |term|
            solution.merge(object.to_sym => term)
          end
        elsif list.to_a.include?(object)
          solution
        else
          nil
        end
      end.flatten.compact.uniq)
    end
  end
end
