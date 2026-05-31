module RDF::TriX
  class Reader < RDF::Reader
    ##
    # LibXML-Ruby implementation of the TriX reader.
    #
    # @see https://rubygems.org/gems/libxml-ruby/
    module LibXML
      OPTIONS = {'trix' => Format::XMLNS}.freeze

      ##
      # Returns the name of the underlying XML library.
      #
      # @return [Symbol]
      def self.library
        :libxml
      end

      ##
      # Initializes the underlying XML library.
      #
      # @param  [Hash{Symbol => Object}] options
      # @return [void]
      def initialize_xml(input, **options)
        require 'libxml' unless defined?(::LibXML)
        @xml = case input
          when File         then ::LibXML::XML::Document.file(input.path)
          when IO, StringIO then ::LibXML::XML::Document.io(input)
          else ::LibXML::XML::Document.string(input.to_s)
        end
      end

    protected

      ##
      # @private
      def find_graphs(&block)
        @xml.find('//trix:graph', OPTIONS).each(&block)
      end

      ##
      # @private
      def read_base
        base = @xml.root.attributes.get_attribute_ns("http://www.w3.org/XML/1998/namespace", "base") if @xml && @xml.root
        RDF::URI(base.value) if base
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
        element.find('./trix:triple', OPTIONS)
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
    end # LibXML
  end # Reader
end # RDF::TriX
