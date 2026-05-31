require 'rdf'
require 'ebnf'

module RDF
  ##
  # **`RDF::Turtle`** is an Turtle extension for RDF.rb.
  #
  # @example Requiring the `RDF::Turtle` module
  #   require 'rdf/turtle'
  #
  # @example Parsing RDF statements from an Turtle file
  #   RDF::Turtle::Reader.open("etc/foaf.ttl") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see https://ruby-rdf.github.io/rdf/master/frames
  # @see https://dvcs.w3.org/hg/rdf/raw-file/default/rdf-turtle/index.html
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module Turtle
    require  'rdf/turtle/format'
    autoload :Reader,         'rdf/turtle/reader'
    autoload :FreebaseReader, 'rdf/turtle/freebase_reader'
    autoload :Terminals,      'rdf/turtle/terminals'
    autoload :VERSION,        'rdf/turtle/version'
    autoload :Writer,         'rdf/turtle/writer'
  end
end
