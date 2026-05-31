module RDF::N3::Algebra::Time
  ##
  # For a date-time format string, its time:gmtime is the result of formatting the Universal Time of processing in the format given. If the format string has zero length, then the ISOdate standard format is used. `[ is time:gmtime of ""]`  the therefore the current date time. It will end with "Z" as a timezone code.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-current-dateTime
  class GmTime < RDF::N3::Algebra::ResourceOperator
    NAME = :timeGmTime
    URI = RDF::N3::Time.gmTime

    ##
    # The time:gmTime operator takes string or dateTime and returns current time formatted according to the subject.
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
        RDF::Literal(DateTime.now.new_offset(0).strftime(resource.to_s))
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end
  end
end
