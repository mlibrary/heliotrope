module RDF::N3::Algebra::Str
  # True iff the string is greater than the object when ordered according to Unicode(tm) code order.
  class GreaterThan < RDF::N3::Algebra::ResourceOperator
    NAME = :strGreaterThan
    URI = RDF::N3::Str.greaterThan

    ##
    # The string:greaterThan compares subject with object as strings.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      resource if resource.literal?
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
      case
      when !left.is_a?(RDF::Term) || !right.is_a?(RDF::Term) || !left.compatible?(right)
        log_error(NAME) {"expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"}
      when left > right then RDF::Literal::TRUE
      else RDF::Literal::FALSE
      end
    end
  end
end
