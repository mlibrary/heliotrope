$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))
require 'rdf'

module RDF
  XML = Class.new(Vocabulary("http://www.w3.org/XML/1998/namespace"))

  ##
  # **`RDF::RDFXML`** is an RDF/XML extension for RDF.rb.
  #
  # @example Requiring the `RDF::RDFXML` module
  #   require 'rdf/rdfxml'
  #
  # @example Parsing RDF statements from an XHTML+RDFXML file
  #   RDF::RDFXML::Reader.open("etc/foaf.xml") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see https://rubygems.org/gems/rdf
  # @see http://www.w3.org/TR/REC-rdf-syntax/
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module RDFXML
    require 'rdf/rdfxml/format'
    autoload :Reader,  'rdf/rdfxml/reader'
    autoload :Writer,  'rdf/rdfxml/writer'
    autoload :VERSION, 'rdf/rdfxml/version'

    # Regexp matching an NCName.
    NC_REGEXP = Regexp.new(
      %{^
        (?!\\\\u0301)             # &#x301; is a non-spacing acute accent.
                                  # It is legal within an XML Name, but not as the first character.
        (  [a-zA-Z_]
         | \\\\u[0-9a-fA-F]{4}
        )
        (  [0-9a-zA-Z_\.-]
         | \\\\u([0-9a-fA-F]{4})
        )*
      $},
      Regexp::EXTENDED)
  
    def self.debug?; @debug; end
    def self.debug=(value); @debug = value; end
  end
end
