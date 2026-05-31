module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is greater than the number of which the object is a string representation.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-greater-than
  class GreaterThan < RDF::N3::Algebra::ResourceOperator
    NAME = :mathGreaterThan
    URI = RDF::N3::Math.greaterThan

    ##
    # Resolves inputs as numbers.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      resource.as_number if resource.term?
    end

    # Both subject and object are inputs.
    def input_operand
      RDF::N3::List.new(values: operands)
    end

    ##
    # Returns TRUE if `term1` is greater than `term2`.
    #
    # @param  [RDF::Term] term1
    #   an RDF term
    # @param  [RDF::Term] term2
    #   an RDF term
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @raise  [TypeError] if either operand is not an RDF term or operands are not comperable
    #
    # @see RDF::Term#==
    def apply(term1, term2)
      RDF::Literal(term1 > term2)
    end
  end
end
