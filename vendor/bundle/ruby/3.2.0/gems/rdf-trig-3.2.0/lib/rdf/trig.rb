require 'rdf'
require 'rdf/turtle'

module RDF
  ##
  # **`RDF::TriG`** is an TriG extension for RDF.rb.
  #
  # @example Requiring the `RDF::TriG` module
  #   require 'rdf/trig'
  #
  # @example Parsing RDF statements from an TriG file
  #   RDF::TriG::Reader.open("etc/foaf.trig") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see https://rubydoc.info/github/ruby-rdf/rdf-turtle/
  # @see https://rubydoc.info/github/ruby-rdf/rdf/master/
  # @see https://www.w3.org/TR/trig/
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module TriG
    require  'rdf/trig/format'
    autoload :Reader,     'rdf/trig/reader'
    autoload :VERSION,    'rdf/trig/version'
    autoload :Writer,     'rdf/trig/writer'
  end
end
