# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path("../ld", __FILE__))
require 'rdf' # @see https://rubygems.org/gems/rdf
require 'json/ld'
require 'psych'
require 'yaml_ld/format'

module YAML_LD
  ##
  # **`YAML_LD`** is a YAML-LD extension for RDF.rb.
  #
  # @example Requiring the `YAML_LD` module
  #   require 'yaml_ld'
  #
  # @example Parsing RDF statements from a YAML-LD file
  #   JSON::LD::Reader.open("etc/foaf.YAML_LD") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see https://rubygems.org/gems/rdf
  # @see http://www.w3.org/TR/REC-rdf-syntax/
  #
  # @note Classes and module use `YAML_LD` instead of `YAML_LD`, as `Psych` squats on the `YAML` module.
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)

  autoload :API,                'yaml_ld/api'
  autoload :Reader,             'yaml_ld/reader'
  autoload :Representation,     'yaml_ld/representation'
  autoload :VERSION,            'yaml_ld/version'
  autoload :Writer,             'yaml_ld/writer'

  # YAML-LD profiles
  YAML_LD_NS = "http://www.w3.org/ns/yaml-ld#"
  PROFILES = %w(extended).map {|p| YAML_LD_NS + p}.freeze
end
