module RDF::N3::Algebra::Time
  ##
  # For a date-time format string, its time:localTime is the result of formatting the current time of processing and local timezone in the format given. If the format string has zero length, then the ISOdate standrad format is used.  [ is time:localTime of ""]  the therefore the current date time. It will end with a numeric timezone code or "Z" for UTC (GMT).
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-current-dateTime
  class LocalTime < RDF::N3::Algebra::ResourceOperator
    NAME = :timeLocalTime
    URI = RDF::N3::Time.localTime

    ##
    # The time:localTime operator takes string or dateTime and returns current time formatted according to the subject.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        return nil unless resource.literal?
        resource = "%FT%T%:z" if resource.to_s.empty?
        RDF::Literal(DateTime.now.strftime(resource.to_s))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
