module RDF::N3::Algebra::Str
  # The subject is a list of two strings. The second string is a regular expression in the perl, python style. It must contain one group (a part in parentheses).  If the first string in the list matches the regular expression, then the object is calculated as being the part of the first string which matches the group.
  #
  # @example
  #     ("abcdef" "ab(..)ef") string:scrape "cd"
  class Scrape < RDF::N3::Algebra::ListOperator
    include RDF::N3::Algebra::Builtin
    NAME = :strScrape
    URI = RDF::N3::Str.scrape

    ##
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    # @see RDF::N3::ListOperator#evaluate
    def resolve(list)
      input, regex = list.to_a
      md = Regexp.new(regex.to_s).match(input.to_s)
      RDF::Literal(md[1]) if md
    end

    ##
    # Subclasses may override or supplement validate to perform validation on the list subject
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    def validate(list)
      if super && list.length == 2
        true
      else
        log_error(NAME) {"list must have exactly two entries: #{list.to_sxp}"}
        false
      end
    end
  end
end
