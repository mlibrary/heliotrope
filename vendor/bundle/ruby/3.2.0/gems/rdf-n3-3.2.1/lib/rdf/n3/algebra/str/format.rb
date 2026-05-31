module RDF::N3::Algebra::Str
  # The subject is a list, whose first member is a format string, and whose remaining members are arguments to the format string. The formating string is in the style of python's % operator, very similar to C's sprintf(). The object is calculated from the subject.
  class Format < RDF::N3::Algebra::ListOperator
    include RDF::N3::Algebra::Builtin
    NAME = :strFormat
    URI = RDF::N3::Str.format

    ##
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      format, *args = list.to_a.map(&:value)
      str = RDF::Literal(format % args)
    end
  end
end
