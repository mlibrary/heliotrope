module RDF::N3::Algebra::Str
  # True iff the subject string is the NOT same as object string ignoring differences between upper and lower case.
  class NotEqualIgnoringCase < EqualIgnoringCase
    NAME = :strNotEqualIgnoringCase
    URI = RDF::N3::Str.notEqualIgnoringCase

    ##
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      RDF::Literal(super != RDF::Literal::TRUE)
    end
  end
end
