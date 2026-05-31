# coding: utf-8
require 'base64'

module RDF; class Literal
  ##
  # More specific sub-types of double
  # Derived types
  # @see https://www.w3.org/TR/xpath-functions/#datatypes
  
  ##
  # hexBinary represents arbitrary hex-encoded binary data. The value space of hexBinary is the set of finite-length
  # sequences of binary octets.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#hexBinary
  class HexBinary < RDF::Literal
    DATATYPE = RDF::XSD.hexBinary
    GRAMMAR = %r(\A[0-9a-fA-F]+\Z)

    ##
    # @param  [String] value The encoded form of the literal
    # @option options [String] :object (nil) decoded value
    def initialize(value, datatype: nil, lexical: nil, **options)
      super(value, datatype: datatype, lexical: lexical)
      @object = options.fetch(:object, hex_to_bin(value.to_s))
      @string ||= bin_to_hex(@object)
    end

    ##
    # Converts this literal into its canonical lexical representation.
    #
    # @return [RDF::Literal] `self`
    def canonicalize!
      @string = bin_to_hex(@object)
      self
    end

    ##
    # Returns the encoded value as a string.
    #
    # @return [String]
    def to_s
      @string.to_s
    end

  private
    def bin_to_hex(value)
      value.unpack('H*').first.upcase
    end

    def hex_to_bin(value)
      value.scan(/../).map { |x| x.hex }.pack('c*').force_encoding("BINARY")
    end
  end
  
  ##
  # base64Binary represents Base64-encoded arbitrary binary data. The ·value space· of base64Binary is the set of
  # finite-length sequences of binary octets. For base64Binary data the entire binary stream is encoded using the Base64
  # Alphabet in [RFC 2045].
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#hexBinary
  class Base64Binary < RDF::Literal
    DATATYPE = RDF::XSD.base64Binary

    ##
    # @param  [String, Object] value
    #   If given a string, it will decode it as an object value.
    #   Otherwise, it will take the value as the object and encode to retrieve a value
    # @option options [String] :lexical (nil)
    def initialize(value, datatype: nil, lexical: nil, **options)
      super(value, datatype: datatype, lexical: lexical)
      @object = value.is_a?(String) ? ::Base64.decode64(value) : value
      canonicalize! unless value.is_a?(String)
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    def to_s
      @string || @object.to_s
    end

    ##
    # Converts this literal into its canonical lexical representation.
    #
    # @return [RDF::Literal] `self`
    # @see    https://www.w3.org/TR/xmlschema-2/#dateTime
    def canonicalize!
      @string = ::Base64.encode64(@object)
      self
    end

    ##
    # Returns `true` if the value adheres to the defined grammar of the
    # datatype.
    #
    # @return [Boolean]
    def valid?
      !!Base64.strict_decode64(value.gsub(/\s+/m, ''))
    rescue ArgumentError
      false
    end
  end
end; end #RDF::Literal