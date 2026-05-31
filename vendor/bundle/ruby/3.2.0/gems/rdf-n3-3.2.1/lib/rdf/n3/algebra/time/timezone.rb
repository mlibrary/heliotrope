module RDF::N3::Algebra::Time
  ##
  # For a date-time, its time:timeZone is the trailing timezone offset part, e.g.  "-05:00".
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-timezone-from-dateTime
  class Timezone < RDF::N3::Algebra::ResourceOperator
    NAME = :timeTimezone
    URI = RDF::N3::Time.timeZone

    ##
    # The time:timeZone operator takes string or dateTime and extracts the timeZone component.
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
        RDF::Literal(resource.object.strftime("%Z"))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end

    ##
    # There is no timezone unless it was specified in the lexical form and is not "Z"
    def valid?(subject, object)
      md = subject.value.match(%r(^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[\+-][\d-]+)))
      md && md[1].to_s != 'Z'
    end
  end
end
