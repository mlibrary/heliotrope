require 'rdf'

module RDF
  ##
  # **`RDF::N3`** is an Notation-3 extension for RDF.rb.
  #
  # @example Requiring the `RDF::N3` module
  #   require 'rdf/n3'
  #
  # @example Parsing RDF statements from an N3 file
  #   RDF::N3::Reader.open("etc/foaf.n3") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see https://ruby-rdf.github.io/rdf/
  # @see https://www.w3.org/TR/REC-rdf-syntax/
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module N3
    require 'rdf/n3/algebra'
    require 'rdf/n3/format'
    require 'rdf/n3/vocab'
    require 'rdf/n3/extensions'
    require 'rdf/n3/refinements'
    autoload :List,       'rdf/n3/list'
    autoload :Reader,     'rdf/n3/reader'
    autoload :Reasoner,   'rdf/n3/reasoner'
    autoload :Repository, 'rdf/n3/repository'
    autoload :Terminals,  'rdf/n3/terminals'
    autoload :VERSION,    'rdf/n3/version'
    autoload :Writer,     'rdf/n3/writer'
  end
end