module RDF::TriX
  ##
  # TriX format specification.
  #
  # @example Loading TriX format support
  #   require 'rdf/trix'
  #
  # @example Obtaining a TriX format class
  #   RDF::Format.for(:trix)         #=> RDF::TriX::Format
  #   RDF::Format.for("etc/doap.xml")
  #   RDF::Format.for(:file_name      => "etc/doap.xml")
  #   RDF::Format.for(:file_extension => "xml")
  #   RDF::Format.for(:content_type   => "application/trix")
  #
  # @see https://www.w3.org/2004/03/trix/
  class Format < RDF::Format
    content_type     'application/trix', :extension => :xml
    content_encoding 'utf-8'

    reader { RDF::TriX::Reader }
    writer { RDF::TriX::Writer }

    XMLNS = 'http://www.w3.org/2004/03/trix/trix-1/'
  end # Format
end # RDF::TriX
