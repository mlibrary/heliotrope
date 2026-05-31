$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))
require 'rdf'

##
# Plugin for RDF.rb for extended XSD datatypes.
#
# @example Requiring the `RDF::XSD` module
#   require 'rdf/xsd'
#
# @see https://rubygems.org/gems/rdf
# @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#built-in-datatypes
#
# @author [Gregg Kellogg](https://greggkellogg.net/)
Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'xsd', '*.rb')) {|f|  require f}
