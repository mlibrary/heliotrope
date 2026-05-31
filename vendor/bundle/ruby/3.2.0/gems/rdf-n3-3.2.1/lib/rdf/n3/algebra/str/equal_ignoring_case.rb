module RDF::N3::Algebra::Str
  class EqualIgnoringCase < RDF::N3::Algebra::ResourceOperator
    NAME = :strEqualIgnoringCase
    URI = RDF::N3::Str.equalIgnoringCase

    ##
    # Resolves inputs as lower-case strings.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Literal]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      RDF::Literal(resource.to_s.downcase) if resource.term?
    end

    # Both subject and object are inputs.
    def input_operand
      RDF::N3::List.new(values: operands)
    end

    ##
    # True iff the subject string is the same as object string ignoring differences between upper and lower case.
    #
    # @param  [RDF::Literal] left
    #   a literal
    # @param  [RDF::Literal] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      RDF::Literal(left.to_s == right.to_s)
    end
  end
end
