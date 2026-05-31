require 'rdf' # @see http://rubygems.org/gems/rdf

module RDF
  ##
  # **`RDF::JSON`** is an RDF/JSON extension for RDF.rb.
  #
  # @example Requiring the `RDF::JSON` module
  #   require 'rdf/json'
  #
  # @example Parsing RDF statements from an RDF/JSON file
  #   RDF::JSON::Reader.open("etc/doap.rj") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @example Serializing RDF statements into an RDF/JSON file
  #   RDF::JSON::Writer.open("etc/test.rj") do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Serializing RDF values into RDF/JSON strings
  #   RDF::Node.new('foobar').to_rdf_json.to_json
  #   RDF::URI.new("https://rubygems.org/gems/rdf/").to_rdf_json.to_json
  #   RDF::Literal.new("Hello, world!").to_rdf_json
  #   RDF::Literal.new("Hello, world!", :language => 'en-US').to_rdf_json.to_json
  #   RDF::Literal.new(3.1415).to_rdf_json.to_json
  #   RDF::Literal.new('true', :datatype => RDF::XSD.boolean).to_rdf_json.to_json
  #   RDF::Statement.new(s, p, o).to_rdf_json.to_json
  #
  # @see http://www.rubydoc.info/github/ruby-rdf/rdf/
  # @see http://n2.talis.com/wiki/RDF_JSON_Specification
  # @see http://en.wikipedia.org/wiki/JSON
  #
  # @author [Arto Bendiken](http://ar.to/)
  module JSON
    require 'json'
    require 'rdf/json/extensions'
    require 'rdf/json/format'
    autoload :Reader,  'rdf/json/reader'
    autoload :Writer,  'rdf/json/writer'
    autoload :VERSION, 'rdf/json/version'
  end # JSON
end # RDF
