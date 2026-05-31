module RDF::N3::Algebra::Str
  # True iff the subject string contains the object string, with the comparison done ignoring the difference between upper case and lower case characters.
  class ContainsIgnoringCase < RDF::N3::Algebra::ResourceOperator
    NAME = :strContainsIgnoringCase
    URI = RDF::N3::Str.containsIgnoringCase

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
    # @param  [String] left
    #   a literal
    # @param  [String] right
    #   a literal
    # @return [RDF::Literal::Boolean]
    def apply(left, right)
      RDF::Literal(left.to_s.include?(right.to_s)) 
    end
  end
end
