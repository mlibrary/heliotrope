module RDF::TriX
  class Writer < RDF::Writer
    ##
    # Nokogiri implementation of the TriX writer.
    #
    # @see https://nokogiri.org/
    module Nokogiri
      ##
      # Returns the name of the underlying XML library.
      #
      # @return [Symbol]
      def self.library
        :nokogiri
      end

      ##
      # Initializes the underlying XML library.
      #
      # @param  [Hash{Symbol => Object}] options
      # @return [void]
      def initialize_xml(**options)
        require 'nokogiri' unless defined?(::Nokogiri)
        @xml = ::Nokogiri::XML::Document.new
        @xml.encoding = @encoding
      end

      ##
      # Generates the TriX root element.
      #
      # @return [void]
      def write_prologue
        options = {xmlns: Format::XMLNS, xml: "http://www.w3.org/XML/1998/namespace"}
        options["xml:base"] = base_uri.to_s if base_uri
        @xml << (@trix = create_element(:TriX, nil, options))
        super
      end

      ##
      # Outputs the TriX document.
      #
      # @return [void]
      def write_epilogue
        puts @xml.to_xml
        @xml = @trix = nil
        super
      end

      ##
      # Creates an XML graph element with the given `name`.
      #
      # @param  [RDF::Resource] name
      # @yield  [element]
      # @yieldparam [Nokogiri::XML::Element] element
      # @return [Nokogiri::XML::Element]
      def create_graph(name = nil, &block)
        @trix << (graph = create_element(:graph))
        case name
          when nil then nil
          when RDF::Node then graph << create_element(:id, name.to_s) # non-standard
          else graph << create_element(:uri, name.to_s)
        end
        block.call(graph) if block_given?
        graph
      end

      ##
      # Creates an XML comment element with the given `text`.
      #
      # @param  [String, #to_s] text
      # @return [Nokogiri::XML::Comment]
      def create_comment(text)
        ::Nokogiri::XML::Comment.new(@xml, text.to_s)
      end

      ##
      # Creates an XML element of the given `name`, with optional given
      # `content` and `attributes`.
      #
      # @param  [Symbol, String, #to_s]  name
      # @param  [String, #to_s]          content
      # @param  [Hash{Symbol => Object}] attributes
      # @yield  [element]
      # @yieldparam [Nokogiri::XML::Element] element
      # @return [Nokogiri::XML::Element]
      def create_element(name, content = nil, attributes = {}, &block)
        element = @xml.create_element(name.to_s)
        if xmlns = attributes.delete(:xmlns)
          element.default_namespace = xmlns
        end
        fragment = attributes.delete(:fragment)
        attributes.each { |k, v| element[k.to_s] = v }
        element.content = content.to_s unless content.nil?
        element << fragment if fragment
        block.call(element) if block_given?
        element
      end
    end # Nokogiri
  end # Writer
end # RDF::TriX
