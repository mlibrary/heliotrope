module RDF::N3::Algebra::Math
  ##
  # **schema**:
  # `($a_1 .. $a_n) math:sum $a_s`
  # 
  # **summary**:
  # performs addition of numbers
  # 
  # **definition**:
  # `true` if and only if the arithmetic sum of `$a_1, .. $a_n` equals `$a_s`.
  # Requires either:
  # 
  # 1. all `$a_1, .., $a_n` to be bound; or
  # 2. all but one `$a_i` (subject list) to be bound, and `$a_s` to be bound.
  # 
  # **literal domains**:
  # 
  # * `$a_1 .. $a_n` : `xs:decimal` (or its derived types), `xs:float`, or `xs:double` (see note on type promotion, and casting from string)
  # * `$a_s`: `xs:decimal` (or its derived types), `xs:float`, or `xs:double` (see note on type promotion, and casting from string)
  #
  # @example
  #     { ("3" "5") math:sum ?x } => { ?x :valueOf "3 + 5" } .
  #     { (3 5) math:sum ?x } => { ?x :valueOf "3 + 5 = 8" } .
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-add
  class Sum < RDF::N3::Algebra::ListOperator
    NAME = :mathSum
    URI = RDF::N3::Math[:sum]

    ##
    # Evaluates to the sum of the list elements
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      list.to_a.map(&:as_number).reduce(&:+) || RDF::Literal(0)  # Empty list sums to 0
    end
  end
end
