module RDF::TriX
  class Reader < RDF::Reader
    ##
    # Nokogiri implementation of the TriX reader.
    #
    # @see https://nokogiri.org/
    module Nokogiri
      OPTIONS = {'trix' => Format::XMLNS}.freeze

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
      def initialize_xml(input, **options)
        require 'nokogiri' unless defined?(::Nokogiri)
        @xml = ::Nokogiri::XML(input)
        log_error("Errors: #{@xml.errors.join('\n')}") unless @xml.errors.empty?
        @xml
      end

    protected

      ##
      # @private
      def find_graphs(&block)
        @xml.xpath('//trix:graph', OPTIONS).each(&block)
      end

      ##
      # @private
      def read_base
        base = @xml.root.attribute_with_ns("base", "http://www.w3.org/XML/1998/namespace") if @xml && @xml.root
        RDF::URI(base.to_s) if base
      end

      ##
      # @private
      def read_graph(graph_element)
        name = graph_element.children.select { |node| node.element? && node.name.to_s == 'uri' }.first.content.strip rescue nil
        name ? RDF::URI.intern(name) : nil
      end

      ##
      # @private
      def triple_elements(element)
        element.xpath('./trix:triple', OPTIONS)
      end

      ##
      # @private
      def element_elements(element)
        element.children.select { |node| node.element? }
      end

      ##
      # @private
      def element_content(element)
        element.content
      end
    end # Nokogiri
  end # Reader
end # RDF::TriX
