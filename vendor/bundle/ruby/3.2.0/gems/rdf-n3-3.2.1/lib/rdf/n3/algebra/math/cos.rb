module RDF::N3::Algebra::Math
  ##
  # The subject is an angle expressed in radians. The object is calulated as the cosine value of the subject.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-math-cos
  class Cos < RDF::N3::Algebra::ResourceOperator
    NAME = :mathCos
    URI = RDF::N3::Math.cos

    ##
    # The math:cos operator takes string or number and calculates its cosine. The arc cosine of a concrete object can also calculate a variable subject.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case resource
      when RDF::Query::Variable then resource
      when RDF::Literal
        case position
        when :subject
          as_literal(Math.cos(resource.as_number.object))
        when :object
          as_literal(Math.acos(resource.as_number.object))
        end
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
