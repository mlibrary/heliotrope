# CSVW-specific literal classes

require 'rdf'
require 'rdf/xsd'

module RDF::Tabular
  ##
  # A JSON literal.
  class JSON < RDF::Literal
    DATATYPE = RDF::Tabular::CSVW.json
    GRAMMAR  = nil

    ##
    # @param  [Object] value
    # @option options [String] :lexical (nil)
    def initialize(value, **options)
      @datatype = options[:datatype] || DATATYPE
      @string   = options[:lexical] if options.has_key?(:lexical)
      if value.is_a?(String)
        @string ||= value
      else
        @object = value
      end
    end

    ##
    # Parse value, if necessary
    #
    # @return [Object]
    def object
      @object ||= ::JSON.parse(value)
    end

    def to_s
      @string ||= value.to_json
    end
  end
end