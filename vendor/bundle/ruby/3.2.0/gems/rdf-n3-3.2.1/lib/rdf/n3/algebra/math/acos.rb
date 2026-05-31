module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the arc cosine value of the subject.
  class ACos < RDF::N3::Algebra::ResourceOperator
    NAME = :mathACos
    URI = RDF::N3::Math.acos

    ##
    # The math:acos operator takes string or number and calculates its arc cosine.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        as_literal(Math.acos(resource.as_number.object))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
