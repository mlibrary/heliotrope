# coding: utf-8
module RDF; class Literal
  ##
  # nonPositiveInteger is derived from integer by setting the value of maxInclusive to be 0. This results in
  # the standard mathematical concept of the non-positive integers. The value space of nonPositiveInteger is the
  # infinite set `{...,-2,-1,0}`. The base type of nonPositiveInteger is integer.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#nonPositiveInteger
  class NonPositiveInteger < Integer
    DATATYPE = RDF::XSD.nonPositiveInteger
    GRAMMAR  = /^(?:[\+\-]?0)|(?:-\d+)$/.freeze

    ##
    # Returns `self` negated.
    #
    # @return [RDF::Literal::Numeric]
    def -@
      if object != 0
        # XXX Raise error?
      end
      super
    end

    def valid?
      super && @object <= 0
    end
  end
  
  ##
  # negativeInteger is derived from nonPositiveInteger by setting the value of maxInclusive to be -1. This
  # results in the standard mathematical concept of the negative integers. The value space of negativeInteger is
  # the infinite set `{...,-2,-1}`. The base type of negativeInteger is nonPositiveInteger.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#negativeInteger
  class NegativeInteger < NonPositiveInteger
    GRAMMAR  = /^\-\d+$/.freeze
    DATATYPE = RDF::XSD.negativeInteger

    ##
    # Returns `self` negated.
    #
    # @return [RDF::Literal::Numeric]
    def -@
      if object != 0
        # XXX Raise error?
      end
      self.class.new(-self.object)
    end

    def valid?
      super && @object < 0
    end
  end
  
  ##
  # long is derived from integer by setting the value of maxInclusive to be 9223372036854775807
  # and minInclusive to be -9223372036854775808.
  #
  # The base type of long is integer.
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#long
  class Long < Integer
    DATATYPE = RDF::XSD.long
    
    def valid?
      super && @object >= -9223372036854775808 && @object <= 9223372036854775807
    end
  end
  
  ##
  # int is derived from long by setting the value of maxInclusive to be 2147483647 and minInclusive to be
  # -2147483648. The base type of int is long.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#int
  class Int < Long
    DATATYPE = RDF::XSD.int
    
    def valid?
      super && @object >= -2147483648 && @object <= 2147483647
    end
  end
  
  ##
  # short is derived from int by setting the value of maxInclusive to be 32767 and minInclusive to be
  # -32768. The base type of short is int.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#short
  class Short < Int
    DATATYPE = RDF::XSD.short
    
    def valid?
      super && @object >= -32768 && @object <= 32767
    end
  end
  
  ##
  # byte is derived from short by setting the value of maxInclusive to be 127 and minInclusive to be -128.
  # The base type of byte is short.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#byte
  class Byte < Short
    DATATYPE = RDF::XSD.byte
    
    def valid?
      super && @object >= -128 && @object <= 127
    end
  end

  ##
  # nonNegativeInteger is derived from integer by setting the value of minInclusive to be 0. This results in
  # the standard mathematical concept of the non-negative integers. The value space of nonNegativeInteger is the
  # infinite set [0,1,2,...]. The base type of nonNegativeInteger is integer.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#nonNegativeInteger
  class NonNegativeInteger < Integer
    GRAMMAR  = /^(?:(?:[\+\-]?0)|(?:\+?\d+))$/.freeze
    DATATYPE = RDF::XSD.nonNegativeInteger

    def valid?
      super && @object >= 0
    end
  end
  
  ##
  # positiveInteger is derived from nonNegativeInteger by setting the value of minInclusive to be 1. This
  # results in the standard mathematical concept of the positive integer numbers. The value space of
  # positiveInteger is the infinite set [1,2,...]. The base type of positiveInteger is nonNegativeInteger.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#positiveInteger
  class PositiveInteger < NonNegativeInteger
    GRAMMAR  = /^\+?\d+$/.freeze
    DATATYPE = RDF::XSD.positiveInteger

    def valid?
      super && @object > 0
    end
  end
  
  ##
  # unsignedLong is derived from nonNegativeInteger by setting the value of maxInclusive to be
  # 18446744073709551615. The base type of unsignedLong is nonNegativeInteger.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#unsignedLong
  class UnsignedLong < NonNegativeInteger
    GRAMMAR  = /^\d+$/.freeze
    DATATYPE = RDF::XSD.unsignedLong
    
    def valid?
      super && @object >= 0 && @object <= 18446744073709551615
    end
  end
  
  ##
  # unsignedInt is derived from unsignedLong by setting the value of maxInclusive to be 4294967295. The base
  # type of unsignedInt is unsignedLong.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#unsignedInt
  class UnsignedInt < UnsignedLong
    DATATYPE = RDF::XSD.unsignedInt
    
    def valid?
      super && @object >= 0 && @object <= 4294967295
    end
  end
  
  ##
  # unsignedShort is derived from unsignedInt by setting the value of maxInclusive to be 65535. The base
  # type of unsignedShort is unsignedInt.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#unsignedShort
  class UnsignedShort < UnsignedInt
    DATATYPE = RDF::XSD.unsignedShort
    
    def valid?
      super && @object >= 0 && @object <= 65535
    end
  end
  
  ##
  # unsignedByte is derived from unsignedShort by setting the value of maxInclusive to be 255. The base
  # type of unsignedByte is unsignedShort.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#unsignedByte
  class UnsignedByte < UnsignedShort
    DATATYPE = RDF::XSD.unsignedByte
    
    def valid?
      super && @object >= 0 && @object <= 255
    end
  end
end; end #RDF::Literal