module RDF::Turtle
  ##
  # Turtle format specification.
  #
  # @example Obtaining an Turtle format class
  #     RDF::Format.for("etc/foaf.ttl")
  #     RDF::Format.for(file_name:      "etc/foaf.ttl")
  #     RDF::Format.for(file_extension: "ttl")
  #     RDF::Format.for(content_type:   "text/turtle")
  #
  # @example Obtaining serialization format MIME types
  #     RDF::Format.content_types      #=> {"text/turtle" => [RDF::Turtle::Format]}
  #
  # @example Obtaining serialization format file extension mappings
  #     RDF::Format.file_extensions    #=> {ttl: "text/turtle"}
  #
  # @see https://www.w3.org/TR/rdf-testcases/#ntriples
  class Format < RDF::Format
    content_type     'text/turtle',
                     extension: :ttl,
                     uri: 'http://www.w3.org/ns/formats/Turtle',
                     aliases: %w(
                       text/rdf+turtle
                       application/turtle;q=0.2
                       application/x-turtle;q=0.2
                     )
    content_encoding 'utf-8'

    reader { RDF::Turtle::Reader }
    writer { RDF::Turtle::Writer }

    ##
    # Sample detection to see if it matches Turtle (or N-Triples)
    #
    # Use a text sample to detect the format of an input file. Sub-classes implement
    # a matcher sufficient to detect probably format matches, including disambiguating
    # between other similar formats.
    #
    # @param [String] sample Beginning several bytes (~ 1K) of input.
    # @return [Boolean]
    def self.detect(sample)
      !!sample.match(%r(
        (?:@(base|prefix)) |                                            # Turtle keywords
        ["']{3} |                                                       # STRING_LITERAL_LONG_SINGLE_QUOTE/2
        "[^"]*"^^ | "[^"]*"@ |                                          # Typed/Language literals
        (?:
          (?:\s*(?:(?:<[^>]*>) | (?:\w*:\w+) | (?:"[^"]*"))\s*[,;]) ||
          (?:\s*(?:(?:<[^>]*>) | (?:\w*:\w+) | (?:"[^"]*"))){3}
        )
      )mx) && !(
        sample.match(%r([{}])) ||                                       # TriG
        sample.match(%r(@keywords|=>|\{)) ||                            # N3
        sample.match(%r(<(?:\/|html|rdf))i) ||                          # HTML, RDF/XML
        sample.match(%r(^(?:\s*<[^>]*>){4}.*\.\s*$)) ||                 # N-Quads
        sample.match(%r("@(context|subject|iri)"))                      # JSON-LD
      )
    end

    # List of symbols used to lookup this format
    def self.symbols
      [:turtle, :ttl]
    end
  end
end
