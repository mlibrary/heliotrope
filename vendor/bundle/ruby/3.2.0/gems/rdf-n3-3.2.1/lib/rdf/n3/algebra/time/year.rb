module RDF::N3::Algebra::Time
  ##
  # For a date-time, its time:year is  the year component.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-year-from-dateTime
  class Year < RDF::N3::Algebra::ResourceOperator
    NAME = :timeYear
    URI = RDF::N3::Time.year

    ##
    # The time:year operator takes string or dateTime and extracts the year component.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        resource = resource.as_datetime
        RDF::Literal(resource.object.strftime("%Y").to_i)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
