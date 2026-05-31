module RDF::N3::Algebra::Math
  ##
  # The subject is a list of numbers. The object is calculated as the arithmentic product of those numbers.
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-multiply
  class Product < RDF::N3::Algebra::ListOperator
    NAME = :mathProduct
    URI = RDF::N3::Math.product

    ##
    # The math:product operator takes a list of strings or numbers and calculates their sum.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      list.to_a.map(&:as_number).reduce(&:*) || RDF::Literal(1)  # Empty list product is 1
    end
  end
end
