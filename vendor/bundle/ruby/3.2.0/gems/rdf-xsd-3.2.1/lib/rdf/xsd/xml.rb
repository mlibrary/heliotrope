# Use Nokogiri when available, and REXML otherwise:
begin
  require 'nokogiri'
  begin
    require 'equivalent-xml'
  rescue LoadError => e
    :rexml # Uses Rexml for equivalent, even with Nokogiri if equivalent-xml is not present.
  end
rescue LoadError => e
  :rexml
end

module RDF; class Literal
  ##
  # An XML literal.
  #
  # XML Literals are maintained in a lexical form, unless an object form is provided.
  # The both lexical and object forms are presumed to be in Exclusive Canonical XML.
  # As generating this form is dependent on the context of the XML Literal from the
  # original document, canonicalization cannot be performed directly within this
  # class.
  #
  # This gem includes Exclusive Canonical XML extensions `Nokogiri::XML::Node#c14nxl`,
  # `Nokogiri::XML::NodeSet#c14nxl`, `REXML::Element#c14nxl` and `Array#c14nxl` (necessary
  # for REXML node children, which is the REXML implementation of a NodeSet)
  #
  # @see   https://www.w3.org/TR/rdf-concepts/#section-XMLLiteral
  # @see   https://www.w3.org/TR/rdfa-core/#s_xml_literals
  # @see   https://www.w3.org/TR/xml-exc-c14n/
  class XML < Literal
    DATATYPE = RDF.XMLLiteral
    GRAMMAR  = nil

    ##
    # @param  [Object] value
    # @param [String] lexical (nil)
    # @option options [:nokogiri, :rexml] :library
    #   Library to use, defaults to :nokogiri if available, :rexml otherwise
    def initialize(value, datatype: nil, lexical: nil, **options)
      @datatype = datatype || DATATYPE
      @string   = lexical if lexical
      if value.is_a?(String)
        @string ||= value
      else
        @object = value
      end

      @library = case options[:library]
      when nil
        # Use Nokogiri when available, and REXML or Hpricot otherwise:
        defined?(::Nokogiri) ? :nokogiri : :rexml
      when :nokogiri, :rexml
        options[:library]
      else
        raise ArgumentError.new("expected :rexml or :nokogiri, but got #{options[:library].inspect}")
      end
    end

    ##
    # Parse value, if necessary
    #
    # @return [Object]
    def object
      @object ||= case @library
      when :nokogiri  then parse_nokogiri(value)
      when :rexml     then parse_rexml(value)
      end
    end

    def to_s
      @string ||= (@object.is_a?(Array) ? @object.map(&:to_s).join("") : @object.to_s)
    end

    ##
    # XML Equivalence. XML Literals can be compared with each other or with xsd:strings
    #
    # @param [Object] other
    # @return [Boolean] `true` or `false`
    #
    # @see https://www.w3.org/TR/rdf-concepts/#section-XMLLiteral
    def eql?(other)
      if other.is_a?(Literal::XML)
        case @library
        when :nokogiri  then equivalent_nokogiri(other)
        when :rexml     then equivalent_rexml(other)
        end
      elsif other.is_a?(Literal) && (other.plain? || other.datatype == RDF::XSD.string)
        value == other.value
      else
        super
      end
    end

    private
    
    # Nokogiri implementations
    if defined?(::Nokogiri)
      ##
      # Parse the value either as a NodeSet, as results are equivalent if it is just a node
      def parse_nokogiri(value)
        Nokogiri::XML.parse("<root>#{value}</root>").root.children
      end

      # Use equivalent-xml to determine equivalence
      def equivalent_nokogiri(other)
        if defined?(::EquivalentXml)
          EquivalentXml.equivalent?(object, other.object)
        else
          equivalent_rexml(other)
        end
      end
    end
    
    ##
    # Parse the value either as a NodeSet, as results are equivalent if it is just a node
    def parse_rexml(value)
      REXML::Document.new("<root>#{value}</root>").root.children
    end
    

    # Simple equivalence test for REXML
    def equivalent_rexml(other)
      begin
        require 'active_support'
        require 'active_support/core_ext'
      rescue LoadError => e
        # string equivalence
      end

      if Hash.respond_to?(:from_xml)
        Hash.from_xml("<root>#{self}</root>") == Hash.from_xml("<root>#{other}</root>")
      else
        # Poor mans equivalent
        value == other.value
      end
    end
  end # class XML
  
  ##
  # An HTML literal.
  #
  # HTML Literals are managed equivalent to XML Literals. Processors
  # are responsible for coercing the input to an
  # [DOM DocumentFragment](https://www.w3.org/TR/dom/#interface-documentfragment).
  #
  # @see   https://dvcs.w3.org/hg/rdf/raw-file/default/rdf-concepts/index.html#section-html
  class HTML < XML
  end
end; end
