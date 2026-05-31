module RDF::TriG
  ##
  # TriG format specification.
  #
  # @example Obtaining an TriG format class
  #     RDF::Format.for("etc/foaf.trig")
  #     RDF::Format.for(:file_name      => "etc/foaf.trig")
  #     RDF::Format.for(file_extension: "trig")
  #     RDF::Format.for(:content_type   => "application/trig")
  #
  # @example Obtaining serialization format MIME types
  #     RDF::Format.content_types      #=> {"application/trig" => [RDF::TriG::Format]}
  #
  # @example Obtaining serialization format file extension mappings
  #     RDF::Format.file_extensions    #=> {trig: "application/trig"}
  #
  # @see https://www.w3.org/TR/rdf-testcases/#ntriples
  class Format < RDF::Format
    content_type     'application/trig',  extension: :trig, alias: 'application/x-trig;q=0.2'
    content_encoding 'utf-8'

    reader { RDF::TriG::Reader }
    writer { RDF::TriG::Writer }

    ##
    # Sample detection to see if it matches TriG
    #
    # Use a text sample to detect the format of an input file. Sub-classes implement
    # a matcher sufficient to detect probably format matches, including disambiguating
    # between other similar formats.
    #
    # @param [String] sample Beginning several bytes (~ 1K) of input.
    # @return [Boolean]
    def self.detect(sample)
      !!sample.match(%r(
        (?:
          (?:\s*(?:(?:<[^>]*>) | (?:\w*:\w+) | (?:"[^"]*")))?           # IRIref
          \s*\{                                                         # Graph Start
          (?:
            (?:\s*(?:(?:<[^>]*>) | (?:\w*:\w+) | (?:"[^"]*"))\s*[,;]) ||
            (?:\s*(?:(?:<[^>]*>) | (?:\w*:\w+) | (?:["']+[^"']*["']+))){3}
          )*                                                            # triples
          [\s\.]*\}\s*                                                  # Graph end
        )
      )mx) && !(
        sample.match(%r(@keywords|=)) ||                                # N3
        sample.match(%r(<(?:\/|html|rdf))i) ||                          # HTML, RDF/XML
        sample.match(%r(^(?:\s*<[^>]*>){4}.*\.\s*$)) ||                 # N-Quads
        sample.match(%r("@(context|subject|iri)"))                      # JSON-LD
      )
    end
  end
end
