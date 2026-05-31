module RDF::RDFa
  ##
  # RDFa format specification.
  #
  # @example Obtaining an RDFa format class
  #   RDF::Format.for(:rdfa)     #=> RDF::RDFa::Format
  #   RDF::Format.for("etc/doap.html")
  #   RDF::Format.for(file_name:      "etc/doap.html")
  #   RDF::Format.for(file_extension: "html")
  #   RDF::Format.for(content_type:   "text/html")
  #   RDF::Format.for(content_type:   "application/xhtml+xml")
  #
  # @example Obtaining serialization format MIME types
  #   RDF::Format.content_types      #=> {"text/html" => [RDF::RDFa::Format]}
  #
  # @example Obtaining serialization format file extension mappings
  #   RDF::Format.file_extensions    #=> {xhtml: "application/xhtml+xml"}
  #
  # @see https://www.w3.org/TR/rdf-testcases/#ntriples
  class Format < RDF::Format
    content_encoding 'utf-8'
    content_type     'text/html;q=0.5',
      aliases: %w(application/xhtml+xml;q=0.7 image/svg+xml;q=0.4),
      extensions: [:html, :xhtml, :svg],
      uri: 'http://www.w3.org/ns/formats/RDFa'
    reader { RDF::RDFa::Reader }
    writer { RDF::RDFa::Writer }

    ##
    # Sample detection to see if it matches RDFa (not RDF/XML or Microdata)
    #
    # Use a text sample to detect the format of an input file. Sub-classes implement
    # a matcher sufficient to detect probably format matches, including disambiguating
    # between other similar formats.
    #
    # @param [String] sample Beginning several bytes (~ 1K) of input.
    # @return [Boolean]
    def self.detect(sample)
      (sample.match(/<[^>]*(about|resource|prefix|typeof|property|vocab)\s*="[^>]*>/m) ||
       sample.match(/<[^>]*DOCTYPE\s+html[^>]*>.*xmlns:/im)
      ) && !sample.match(/<(\w+:)?(RDF)/)
    end

    def self.symbols
      [:rdfa, :lite, :html, :xhtml, :svg]
    end
  end
end
