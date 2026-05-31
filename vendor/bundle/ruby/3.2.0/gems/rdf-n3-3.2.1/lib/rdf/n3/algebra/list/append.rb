module RDF::N3::Algebra::List
  ##
  # Iff the subject is a list of lists and the concatenation of all those lists  is the object, then this is true. The object can be calculated as a function of the subject.
  #
  # @example
  #     ( (1 2) (3 4) ) list:append (1 2 3 4).
  #
  # The object can be calculated as a function of the subject.
  class Append < RDF::N3::Algebra::ListOperator
    NAME = :listAppend
    URI = RDF::N3::List.append

    ##
    # Resolves this operator using the given variable `bindings`.
    # If the last operand is a variable, it creates a solution for each element in the list.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      flattened = list.to_a.map(&:to_a).flatten
      # Bind a new list based on the values, whos subject use made up from original list subjects
      subj = RDF::Node.intern(list.map(&:subject).hash)
      RDF::N3::List.new(subject: subj, values: flattened)
    end

    ##
    # The list argument must be a pair of literals.
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    # @see RDF::N3::ListOperator#validate
    def validate(list)
      if super && list.to_a.all? {|li| li.list?}
        true
      else
        log_error(NAME) {"operand is not a list of lists: #{list.to_sxp}"}
        false
      end
    end
  end
end
