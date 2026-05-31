module RDF::N3::Algebra::Math
  ##
  # True iff the subject is a string representation of a number which  is NOT LESS than a number of which the object is a string representation.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-less-than
  class NotLessThan < LessThan
    NAME = :mathNotLessThan
    URI = RDF::N3::Math.notLessThan

    ##
    # Returns TRUE if `term1` is greater than or equal to `term2`.
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
      RDF::Literal(super != RDF::Literal::TRUE)
    end
  end
end
