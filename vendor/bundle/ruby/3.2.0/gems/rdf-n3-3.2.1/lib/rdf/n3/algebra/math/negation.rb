module RDF::N3::Algebra::Math
  ##
  # The subject or object is calculated to be the negation of the other.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
  class Negation < RDF::N3::Algebra::ResourceOperator
    include RDF::N3::Algebra::Builtin

    NAME = :mathNegation
    URI = RDF::N3::Math.negation

    ##
    # The math:negation operator takes may have either a bound subject or object.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case resource
      when RDF::Query::Variable
        resource
      when RDF::Literal
        as_literal(-resource.as_number)
      else
        nil
      end
    end

    ##
    # Input is either the subject or object
    #
    # @return [RDF::Term]
    def input_operand
      RDF::N3::List.new(values: operands)
    end
  end
end
