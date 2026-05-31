module RDF; class Literal
  # Note that in XML Schema, Float is not really derived from Double,
  # but implementations are identical in Ruby
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#float
  class Float < Double
    DATATYPE = RDF::XSD.float
  end
end; end #RDF::Literal