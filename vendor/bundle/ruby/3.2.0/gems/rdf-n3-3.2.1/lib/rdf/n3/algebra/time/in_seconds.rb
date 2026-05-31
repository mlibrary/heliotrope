module RDF::N3::Algebra::Time
  ##
  # Iff the _subject_ is a `xsd:dateTime` and the _object_ is the integer number of seconds since the beginning of the era on a given system.  Don't assume a particular value, always test for it. The _object_ can be calculated as a function of the _subject_.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-timezone-from-dateTime
  class InSeconds < RDF::N3::Algebra::ResourceOperator
    NAME = :timeInSeconds
    URI = RDF::N3::Time.inSeconds

    ##
    # The time:inseconds operator takes may have either a bound subject or object.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      case position
      when :subject
        case resource
        when RDF::Query::Variable
          resource
        when RDF::Literal
          resource = resource.as_datetime
          # Subject evaluates to seconds from the epoc
          RDF::Literal::Integer.new(resource.object.strftime("%s"))
        else
          nil
        end
      when :object
        case resource
        when RDF::Query::Variable
          resource
        when RDF::Literal
          resource = resource.as_number
          # Object evaluates to the DateTime representation of the seconds form the epoc
          RDF::Literal(RDF::Literal::DateTime.new(::Time.at(resource).utc.to_datetime).to_s)
        else
          nil
        end
      end
    end

    # Either subject or object must be a bound resource
    def valid?(subject, object)
      return true if subject.literal? || object.literal?
      log_error(NAME) {"subject or object are not literals: #{subject.inspect}, #{object.inspect}"}
      false
    end

    ##
    # Return both subject and object operands.
    #
    # @return [RDF::Term]
    def input_operand
      RDF::N3::List.new(values: operands)
    end
  end
end
