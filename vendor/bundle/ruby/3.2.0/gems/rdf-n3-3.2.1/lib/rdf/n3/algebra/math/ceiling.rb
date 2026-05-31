module RDF::N3::Algebra::Math
  ##
  # The object is calculated as the subject upwards to a whole number.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-ceiling
  class Ceiling < RDF::N3::Algebra::ResourceOperator
    NAME = :mathCeiling
    URI = RDF::N3::Math.ceiling

    ##
    # The math:ceiling operator takes string or number and calculates its ceiling.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        as_literal(resource.as_number.ceil)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
