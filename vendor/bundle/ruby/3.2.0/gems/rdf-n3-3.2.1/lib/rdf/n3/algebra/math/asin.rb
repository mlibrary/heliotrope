module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the arc sine value of the subject.
  class ASin < RDF::N3::Algebra::ResourceOperator
    NAME = :mathASin
    URI = RDF::N3::Math.asin

    ##
    # The math:asin operator takes string or number and calculates its arc sine.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        as_literal(Math.asin(resource.as_number.object))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
