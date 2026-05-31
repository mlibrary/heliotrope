$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))
require 'rdf'

module RDF
  ##
  # **`RDF::RDFa`** is an RDFa extension for RDF.rb.
  #
  # @example Requiring the `RDF::RDFa` module
  #   require 'rdf/rdfa'
  #
  # @example Parsing RDF statements from an XHTML+RDFa file
  #   RDF::RDFa::Reader.open("etc/doap.html") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see https://rubygems.org/gems/rdf
  # @see https://www.w3.org/TR/rdfa-syntax/#s_model RDFa 1.0
  # @see https://www.w3.org/TR/2012/REC-rdfa-core-20120607/
  # @see https://www.w3.org/TR/2012/CR-xhtml-rdfa-20120313/
  # @see https://dev.w3.org/html5/rdfa/
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module RDFa
    require 'rdf/rdfa/format'
    require 'rdf/rdfa/vocab'
    require 'rdf/rdfa/patches/string_hacks'
    autoload :Expansion,  'rdf/rdfa/expansion'
    autoload :Context,    'rdf/rdfa/context'
    autoload :Reader,     'rdf/rdfa/reader'
    autoload :Writer,     'rdf/rdfa/writer'
    autoload :VERSION,    'rdf/rdfa/version'

    HTML_RDFA_CONTEXT   = "http://www.w3.org/2011/rdfa-context/html-rdfa-1.1"
    XHTML_RDFA_CONTEXT  = "http://www.w3.org/2011/rdfa-context/xhtml-rdfa-1.1"
    XML_RDFA_CONTEXT    = "http://www.w3.org/2011/rdfa-context/rdfa-1.1"
  end
end
