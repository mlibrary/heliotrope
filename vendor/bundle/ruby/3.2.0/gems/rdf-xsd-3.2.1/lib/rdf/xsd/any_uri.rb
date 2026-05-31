# coding: utf-8
require 'base64'

module RDF; class Literal
  ##
  # More specific sub-types of double
  # Derived types
  # @see https://www.w3.org/TR/xpath-functions/#datatypes
  
  ##
  # anyURI represents a Uniform Resource Identifier Reference (URI).
  # An anyURI value can be absolute or relative, and may have an
  # optional fragment identifier (i.e., it may be a URI Reference).
  # This type should be used to specify the intention that the value fulfills
  # the role of a URI as defined by [RFC 2396], as amended by [RFC 2732].
  #
  # @see https://www.w3.org/TR/xmlschema11-2/#anyURI
  # @see https://www.ietf.org/rfc/rfc2396.txt
  # @see https://www.ietf.org/rfc/rfc2732.txt
  class AnyURI < RDF::Literal
    DATATYPE = RDF::XSD.anyURI

    ##
    # @param  [String, Object] value
    #   If given a string, it will decode it as an object value.
    #   Otherwise, it will take the value as the object and encode to retrieve a value
    # @param [String] lexical (nil)
    def initialize(value, datatype: nil, lexical: nil, **options)
      super(value, datatype: datatype, lexical: lexical)
      @object = RDF::URI(value)
      canonicalize! unless value.is_a?(String)
    end

    ##
    # Converts this literal into its canonical lexical representation.
    #
    # @return [RDF::Literal] `self`
    def canonicalize!
      @string = @object.canonicalize
      self
    end

    ##
    # Returns `true` if the value adheres to the defined grammar of the
    # datatype.
    #
    # @return [Boolean]
    def valid?
      @object.validate! rescue false
    end
  end
end; end #RDF::Literal