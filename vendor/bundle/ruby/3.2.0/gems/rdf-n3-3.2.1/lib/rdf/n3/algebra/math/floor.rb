module RDF::N3::Algebra::Math
  ##
  # The object is calculated as the subject downwards to a whole number.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-floor
  class Floor < RDF::N3::Algebra::ResourceOperator
    NAME = :mathFloor
    URI = RDF::N3::Math.floor

    ##
    # The math:floor operator takes string or number and calculates its floor.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        RDF::Literal(resource.as_number.floor)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
