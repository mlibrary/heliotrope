module RDF::N3::Algebra::Math
  ##
  # **schema**:
  # `$a1 math:equalTo $a2`
  # 
  # **summary**:
  # checks equality of numbers
  # 
  # **definition**:
  # `true` if and only if `$a1` is equal to `$a2`. 
  # Requires both arguments to be either concrete numerals, or variables bound to a numeral.
  # 
  # **literal domains**:
  # 
  # * `$a1`: `xs:decimal` (or its derived types), `xs:float`, or `xs:double`  (see note on type promotion, and casting from string)
  # * `$a2`: `xs:decimal` (or its derived types), `xs:float`, or `xs:double`  (see note on type promotion, and casting from string)
  #
  # @see https://www.w3.org/TR/xpath-functions/#func-numeric-equal
  class EqualTo < RDF::N3::Algebra::ResourceOperator
    NAME = :mathEqualTo
    URI = RDF::N3::Math.equalTo

    ##
    # Resolves inputs as numbers.
    #
    # @param [RDF::Term] resource
    # @param [:subject, :object] position
    # @return [RDF::Term]
    # @see RDF::N3::ResourceOperator#evaluate
    def resolve(resource, position:)
      resource.as_number if resource.term?
    end

    # Both subject and object are inputs.
    def input_operand
      RDF::N3::List.new(values: operands)
    end

    ##
    # Returns TRUE if `term1` and `term2` are the same numeric value.
    #
    # @param  [RDF::Term] term1
    #   an RDF term
    # @param  [RDF::Term] term2
    #   an RDF term
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @raise  [TypeError] if either operand is not an RDF term or operands are not comperable
    #
    # @see RDF::Term#==
    def apply(term1, term2)
      RDF::Literal(term1 == term2)
    end
  end
end
