module RDF::N3::Algebra::Math
  ##
  # The subject is a pair of integers. The object is calculated by dividing the first number of the pair by the second and taking the remainder.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-mod
  class Remainder < RDF::N3::Algebra::ListOperator
    NAME = :mathRemainder
    URI = RDF::N3::Math.remainder

    ##
    # The math:remainder operator takes a pair of strings or numbers and calculates their remainder.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      list.to_a.map(&:as_number).reduce(&:%)
    end

    ##
    # The list argument must be a pair of literals.
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    # @see RDF::N3::ListOperator#validate
    def validate(list)
      if super && list.all? {|li| li.is_a?(RDF::Literal) && li.as_number.is_a?(RDF::Literal::Integer)} && list.length == 2
        true
      else
        log_error(NAME) {"list is not a pair of integers: #{list.to_sxp}"}
        false
      end
    end
  end
end
