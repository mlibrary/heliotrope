module RDF::N3::Algebra::List
  ##
  # Iff the subject is a list and the object is the last thing that list, then this is true. The object can be calculated as a function of the list.
  #
  # @example
  #     { ( 1 2 3 4 5 6 ) list:last 6 } => { :test1 a :SUCCESS }.
  #
  # The object can be calculated as a function of the list.
  class Last < RDF::N3::Algebra::ListOperator
    NAME = :listLast
    URI = RDF::N3::List.last

    ##
    # Resolves this operator using the given variable `bindings`.
    # If the last operand is a variable, it creates a solution for each element in the list.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      list.last
    end
  end
end
