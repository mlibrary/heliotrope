module RDF::N3::Algebra::Str
  # True iff the subject string contains the object string.
  class Contains < RDF::N3::Algebra::ResourceOperator
    NAME = :strContains
    URI = RDF::N3::Str.contains

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

    # Neither subect nor object are considered inputs, and must be resolved before evaluation.
    def input_operand
      RDF::N3::List.new
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
