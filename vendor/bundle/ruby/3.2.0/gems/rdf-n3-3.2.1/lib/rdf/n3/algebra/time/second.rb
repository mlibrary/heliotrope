module RDF::N3::Algebra::Time
  ##
  # For a date-time, its time:second is the seconds component.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-seconds-from-dateTime
  class Second < RDF::N3::Algebra::ResourceOperator
    NAME = :timeSecond
    URI = RDF::N3::Time.second

    ##
    # The time:second operator takes string or dateTime and extracts the seconds component.
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
        RDF::Literal(resource.object.strftime("%S").to_i)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end

    ##
    # There is no second unless it was specified in the lexical form
    def valid?(subject, object)
      subject.value.match?(%r(^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}))
    end
  end
end
