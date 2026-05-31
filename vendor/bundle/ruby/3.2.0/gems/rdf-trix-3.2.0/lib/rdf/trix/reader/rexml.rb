module RDF::TriX
  class Reader < RDF::Reader
    ##
    # REXML implementation of the TriX reader.
    #
    # @see https://www.germane-software.com/software/rexml/
    module REXML
      OPTIONS = {}.freeze

      ##
      # Returns the name of the underlying XML library.
      #
      # @return [Symbol]
      def self.library
        :rexml
      end

      ##
      # Initializes the underlying XML library.
      #
      # @param  [Hash{Symbol => Object}] options
      # @return [void]
      def initialize_xml(input, **options)
        require 'rexml/document' unless defined?(::REXML)
        @xml = ::REXML::Document.new(input, :compress_whitespace => %w{uri})
      end

    protected

      ##
      # @private
      def find_graphs(&block)
        @xml.elements.each('TriX/graph', &block)
      end

      ##
      # @private
      def read_base
        base = @xml.root.attribute("base", "http://www.w3.org/XML/1998/namespace") if @xml && @xml.root
        RDF::URI(base.to_s) if base
      end

      ##
      # @private
      def read_graph(graph_element)
        name = graph_element.elements.select { |element| element.name.to_s == 'uri' }.first.text.strip rescue nil
        name ? RDF::URI.intern(name) : nil
      end

      ##
      # @private
      def triple_elements(element)
        element.get_elements('triple')
      end

      ##
      # @private
      def element_elements(element)
        element.elements.to_a
      end

      ##
      # @private
      def element_content(element)
        element.text
      end
    end # REXML
  end # Reader
end # RDF::TriX
