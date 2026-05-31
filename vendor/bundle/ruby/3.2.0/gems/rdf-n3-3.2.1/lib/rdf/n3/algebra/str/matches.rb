module RDF::N3::Algebra::Str
  # The subject is a string; the object is is a regular expression in the perl, python style.
  # It is true iff the string matches the regexp.
  class Matches < RDF::N3::Algebra::ResourceOperator
    NAME = :strMatches
    URI = RDF::N3::Str.matches

    ##
    # Resolves inputs as strings.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Literal]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      resource if resource.literal?
    end

    # Neither subect nor object are considered inputs, and must be resolved before evaluation.
    def input_operand
      RDF::N3::List.new
    end

    ##
    # Tre if right, treated as a regular expression, matches left
    #
    # @param  [RDF::Literal] left
    #   a simple literal
    # @param  [RDF::Literal] right
    #   a simple literal
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @see https://www.w3.org/TR/xpath-functions/#regex-syntax
    def apply(left, right)
      RDF::Literal(Regexp.new(right.to_s).match?(left.to_s))
    end
  end
end
