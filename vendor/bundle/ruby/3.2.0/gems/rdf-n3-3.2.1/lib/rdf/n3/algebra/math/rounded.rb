module RDF::N3::Algebra::Math
  ##
  # The object is calulated as the subject rounded to the nearest integer.
  class Rounded < RDF::N3::Algebra::ResourceOperator
    NAME = :mathRounded
    URI = RDF::N3::Math.rounded

    ##
    # The math:rounded operator takes string or number rounds it to the next  integer.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        as_literal(resource.as_number.round)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
