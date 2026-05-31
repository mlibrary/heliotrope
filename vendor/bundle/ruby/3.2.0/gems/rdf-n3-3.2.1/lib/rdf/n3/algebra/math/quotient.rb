module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of numbers. The object is calculated by dividing the first number of the pair by the second.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-divide
  class Quotient < RDF::N3::Algebra::ListOperator
    NAME = :mathQuotient
    URI = RDF::N3::Math.quotient

    ##
    # The math:quotient operator takes a pair of strings or numbers and calculates their quotient.
    #
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      list.to_a.map(&:as_number).reduce(&:/)
    end

    ##
    # The list argument must be a pair of literals.
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    # @see RDF::N3::ListOperator#validate
    def validate(list)
      if super && list.all? {|le| le.is_a?(RDF::Literal)} && list.length == 2
        true
      else
        log_error(NAME) {"list is not a pair of literals: #{list.to_sxp}"}
        false
      end
    end
  end
end
