module RDF::N3::Algebra::List
  ##
  # Generates a list of lists when each constituent list is composed of the index and value of each element in the subject.
  #
  # Binds variables in the object list.
  #
  # @example
  #     { (1 2 3) list:iterate ((0 1) (1 2) (2 3)) } => { :test4a a :SUCCESS }.
  class Iterate < RDF::N3::Algebra::ListOperator
    NAME = :listIterate
    URI = RDF::N3::List.iterate

    ##
    # Evaluates this operator using the given variable `bindings`.
    # The subject MUST evaluate to a list and the object to a list composed of two components: index and value.
    #
    # @example
    #    {(1 2 3) list:iterate (?x ?y)} => {:solution :is (?x ?y)} .
    #
    # @example
    #    {(1 2 3) list:iterate ?L} => {:solution :is ?L} .
    #
    # @example
    #    {(1 2 3) list:iterate (1 ?y)} => {:value :is ?y} .
    #
    # @example
    #    {(1 2 3) list:iterate (?x 2)} => {:index :is ?x} .
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
        # If subject evaluated to a BNode, re-expand as a list
        subject = RDF::N3::List.try_list(subject, queryable).evaluate(solution.bindings, formulae: formulae)
        next unless validate(subject)

        object = operand(1).evaluate(solution.bindings, formulae: formulae) || operand(1)
        next unless object
        # If object evaluated to a BNode, re-expand as a list
        object = RDF::N3::List.try_list(object, queryable).evaluate(solution.bindings, formulae: formulae) || object

        if object.list? && object.variable?
          # Create a solution for those entries in subject that match object
          if object.length != 2
            log_error(NAME) {"object is not a list with two entries: #{object.to_sxp}"}
            next
          end
          if object.first.variable? && object.last.variable?
            solutions = RDF::Query::Solutions.new
            subject.each_with_index do |r, i|
              s = solution.merge(object.first.to_sym => RDF::Literal(i), object.last.to_sym => r)
              log_debug(self.class.const_get(:NAME), "result: #{s.to_sxp}")
              solutions << s
            end
            solutions
          elsif object.first.variable?
            # Solution binds indexes to all matching values
            solutions = RDF::Query::Solutions.new
            subject.each_with_index do |r, i|
              next unless r == object.last
              s = solution.merge(object.first.to_sym => RDF::Literal(i))
              log_debug(self.class.const_get(:NAME), "result: #{s.to_sxp}")
              solutions << s
            end
            solutions
          elsif object.last.variable?
            # Solution binds value at specified index
            next unless v = subject.at(object.first)
            s = solution.merge(object.last.to_sym => v)
            log_debug(self.class.const_get(:NAME), "result: #{s.to_sxp}")
            s
          end
        elsif object.variable?
          # Create a solution for each index/value pair in subject
          solutions = RDF::Query::Solutions.new
          subject.each_with_index do |r, i|
            s = solution.merge(object.to_sym => RDF::N3::List[RDF::Literal(i), r])
            log_debug(self.class.const_get(:NAME), "result: #{s.to_sxp}")
            solutions << s
          end
          solutions
        else
          # Evaluates to true if the subject has a matching entry
          same = subject.at(object.first) == object.last
          log_debug(self.class.const_get(:NAME), "result: #{same.inspect}")
          solution if same
        end
      end.flatten.compact.uniq)
    end
  end
end
