module RDF::N3::Algebra::Time
  ##
  # For a date-time, its time:minute is the minutes component.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-minutes-from-dateTime
  class Minute < RDF::N3::Algebra::ResourceOperator
    NAME = :timeMinute
    URI = RDF::N3::Time.minute

    ##
    # The time:minute operator takes string or dateTime and extracts the minute component.
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
        RDF::Literal(resource.object.strftime("%M").to_i)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end

    ##
    # There is no minute unless it was specified in the lexical form
    def valid?(subject, object)
      subject.value.match?(%r(^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}))
    end
  end
end
