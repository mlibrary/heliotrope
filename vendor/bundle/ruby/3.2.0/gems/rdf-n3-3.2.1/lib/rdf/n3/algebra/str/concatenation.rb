module RDF::N3::Algebra::Str
  ##
  # The subject is a list of strings. The object is calculated as a concatenation of those strings.
  #
  # @example
  #     ("a" "b") string:concatenation :s
  class Concatenation < RDF::N3::Algebra::ListOperator
    NAME = :strConcatenation
    URI = RDF::N3::Str.concatenation

    ##
    # The string:concatenation operator takes a list of terms cast to strings and either binds the result of concatenating them to the output variable, removes a solution that does equal the literal object.
    #
    # List entries are stringified using [SPARQL::Algebra::Expression.cast](https://ruby-rdf.github.io/sparql/SPARQL/Algebra/Expression#cast-class_method).
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      RDF::Literal(
        list.to_a.map do |o|
          SPARQL::Algebra::Expression.cast(RDF::XSD.string, o)
        end.join("")
      )
    end
  end
end
