module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the arc tangent value of the subject.
  class ATan < RDF::N3::Algebra::ResourceOperator
    NAME = :mathATan
    URI = RDF::N3::Math.atan

    ##
    # The math:atan operator takes string or number and calculates its arc tangent.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        as_literal(Math.atan(resource.as_number.object))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
