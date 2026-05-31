module RDF::N3::Algebra::Str
  # The subject string; the object is a regular expression in the perl, python style. It is true iff the string does NOT match the regexp.
  class NotMatches < Matches
    NAME = :strNotMatches
    URI = RDF::N3::Str.notMatches

    ##
    # @param  [RDF::Literal] text
    #   a simple literal
    # @param  [RDF::Literal] pattern
    #   a simple literal
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @see https://www.w3.org/TR/xpath-functions/#regex-syntax
    def apply(text, pattern)
      RDF::Literal(super != RDF::Literal::TRUE)
    end
  end
end
