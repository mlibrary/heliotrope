module RDF::N3::Algebra::List
  ##
  # Iff the object is a list and the subject is in that list, then this is true.
  #
  # @example
  #     { 1 list:in  (  1 2 3 4 5 ) } => { :test4a a :SUCCESS }.
  class In < RDF::N3::Algebra::ListOperator
    NAME = :listIn
    URI = RDF::N3::List.in

    ##
    # Evaluates this operator using the given variable `bindings`.
    # If the first operand is a variable, it creates a solution for each element in the list.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param [RDF::Query::Solutions] solutions
    #   solutions for chained queries
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      RDF::Query::Solutions(solutions.map do |solution|
        subject = operand(0).evaluate(solution.bindings, formulae: formulae) || operand(0)
        # Might be a variable or node evaluating to a list in queryable, or might be a list with variables
        list = operand(1).evaluate(solution.bindings, formulae: formulae)
        next unless list
        # If it evaluated to a BNode, re-expand as a list
        list = RDF::N3::List.try_list(list, queryable).evaluate(solution.bindings, formulae: formulae)

        log_debug(NAME) {"subject: #{subject.to_sxp}, list: #{list.to_sxp}"}
        unless list.list? && list.valid?
          log_error(NAME) {"operand is not a list: #{list.to_sxp}"}
          next
        end

        if subject.variable?
          # Bind all list entries to this solution, creates an array of solutions
          list.to_a.map do |term|
            solution.merge(subject.to_sym => term)
          end
        elsif list.to_a.include?(subject)
          solution
        else
          nil
        end
      end.flatten.compact.uniq)
    end
  end
end
