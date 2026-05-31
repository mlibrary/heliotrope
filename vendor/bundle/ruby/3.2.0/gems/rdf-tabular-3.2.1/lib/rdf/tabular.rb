$:.unshift(File.expand_path("..", __FILE__))
require 'rdf' # @see https://rubygems.org/gems/rdf
require 'csv'

module RDF
  ##
  # **`RDF::Tabular`** is a Tabular/CSV extension for RDF.rb.
  #
  # @see https://w3c.github.io/csvw/
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module Tabular
    require 'rdf/tabular/format'
    autoload :Column,         'rdf/tabular/metadata'
    autoload :CSVW,           'rdf/tabular/csvw'
    autoload :Dialect,        'rdf/tabular/metadata'
    autoload :JSON,           'rdf/tabular/literal'
    autoload :Metadata,       'rdf/tabular/metadata'
    autoload :Reader,         'rdf/tabular/reader'
    autoload :Schema,         'rdf/tabular/metadata'
    autoload :Table,          'rdf/tabular/metadata'
    autoload :TableGroup,     'rdf/tabular/metadata'
    autoload :Transformation, 'rdf/tabular/metadata'
    autoload :UAX35,          'rdf/tabular/uax35'
    autoload :VERSION,        'rdf/tabular/version'

    # Metadata errors detected
    class Error < RDF::ReaderError; end

    # Relative location of site-wide configuration file
    SITE_WIDE_CONFIG = "/.well-known/csvm".freeze
    SITE_WIDE_DEFAULT = %(
      {+url}-metadata.json
      csv-metadata.json
    ).gsub(/^\s+/, '').freeze

    def self.debug?; @debug; end
    def self.debug=(value); @debug = value; end
  end
end