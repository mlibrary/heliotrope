module RDF::N3::Algebra::Time
  ##
  # For a date-time, its time:month is the two-digit month.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-month-from-dateTime
  class Month < RDF::N3::Algebra::ResourceOperator
    NAME = :timeMonth
    URI = RDF::N3::Time.month

    ##
    # The time:month operator takes string or dateTime and extracts the month component.
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
        RDF::Literal(resource.object.strftime("%m").to_i)
      when :object
        return nil unless resource.literal? || resource.variable?
        resource
      end
    end

    ##
    # There is no month unless it was specified in the lexical form
    def valid?(subject, object)
      subject.value.match?(%r(^\d{4}-\d{2}))
    end
  end
end
