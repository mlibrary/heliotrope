module RDF::TriX
  class Writer < RDF::Writer
    ##
    # REXML implementation of the TriX writer.
    #
    # @see https://www.germane-software.com/software/rexml/
    module REXML
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
      def initialize_xml(**options)
        require 'rexml/document' unless defined?(::REXML)
        @xml = ::REXML::Document.new(nil, :attribute_quote => :quote)
        @xml << ::REXML::XMLDecl.new(::REXML::XMLDecl::DEFAULT_VERSION, @encoding)
      end

      ##
      # Generates the TriX root element.
      #
      # @return [void]
      def write_prologue
        options = {"xmlns" => Format::XMLNS, "xml" => "http://www.w3.org/XML/1998/namespace"}
        options["xml:base"] = base_uri.to_s if base_uri
        @trix = @xml.add_element('TriX', options)
        super
      end

      ##
      # Outputs the TriX document.
      #
      # @return [void]
      def write_epilogue
        formatter = ::REXML::Formatters::Pretty.new((@options[:indent] || 2).to_i, false)
        formatter.compact = true
        formatter.write(@xml, @output)
        puts # add a line break after the last line
        @xml = @trix = nil
        super
      end

      ##
      # Creates an XML graph element with the given `name`.
      #
      # @param  [RDF::Resource] name
      # @yield  [element]
      # @yieldparam [REXML::Element] element
      # @return [REXML::Element]
      def create_graph(name = nil, &block)
        graph = @trix.add_element('graph')
        case name
          when nil then nil
          when RDF::Node then graph.add_element('id').text = name.to_s # non-standard
          else graph.add_element('uri').text = name.to_s
        end
        block.call(graph) if block_given?
        graph
      end

      ##
      # Creates an XML comment element with the given `text`.
      #
      # @param  [String, #to_s] text
      # @return [REXML::Comment]
      def create_comment(text)
        ::REXML::Comment.new(text.to_s)
      end

      ##
      # Creates an XML element of the given `name`, with optional given
      # `content` and `attributes`.
      #
      # @param  [Symbol, String, #to_s]  name
      # @param  [String, #to_s]          content
      # @param  [Hash{Symbol => Object}] attributes
      # @yield  [element]
      # @yieldparam [REXML::Element] element
      # @return [REXML::Element]
      def create_element(name, content = nil, attributes = {}, &block)
        element = ::REXML::Element.new(name.to_s, nil, @xml.context)
        fragment = attributes.delete(:fragment)
        attributes.each { |k, v| element.add_attribute(k.to_s, v) }
        element.text = content.to_s unless content.nil?
        element << fragment if fragment
        block.call(element) if block_given?
        element
      end
    end # REXML
  end # Writer
end # RDF::TriX
