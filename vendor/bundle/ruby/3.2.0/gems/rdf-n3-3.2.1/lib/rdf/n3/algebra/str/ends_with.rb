module RDF::N3::Algebra::Str
  # True iff the subject string ends with the object string.
  class EndsWith < RDF::N3::Algebra::ResourceOperator
    NAME = :strEndsWith
    URI = RDF::N3::Str.endsWith

    ##
    # Resolves inputs as strings.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Literal]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      resource if resource.term?
    end

    # Both subject and object are inputs.
    def input_operand
      RDF::N3::List.new(values: operands)
    end

    ##
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      RDF::Literal(left.to_s.end_with?(right.to_s))
    end
  end
end
