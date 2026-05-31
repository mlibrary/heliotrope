module RDF::N3::Algebra::Str
  # A built-in for replacing characters or sub. takes a list of 3 strings; the first is the input data, the second the old and the third the new string. The object is calculated as the replaced string.
  #
  # @example
  #     ("fofof bar", "of", "baz") string:replace "fbazbaz bar"
  class Replace < RDF::N3::Algebra::ListOperator
    include RDF::N3::Algebra::Builtin
    NAME = :strReplace
    URI = RDF::N3::Str.replace

    ##
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      format, *args = list.to_a.map(&:value)
      input, old_str, new_str = list.to_a
      RDF::Literal(input.to_s.gsub(old_str.to_s, new_str.to_s))
    end

    ##
    # Subclasses may override or supplement validate to perform validation on the list subject
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    def validate(list)
      if super && list.length == 3 && list.to_a.all?(&:literal?)
        true
      else
        log_error(NAME) {"list must have exactly three entries: #{list.to_sxp}"}
        false
      end
    end
  end
end
