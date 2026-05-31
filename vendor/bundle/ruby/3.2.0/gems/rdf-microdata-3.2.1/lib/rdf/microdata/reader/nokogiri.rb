module RDF::Microdata
  class Reader < RDF::Reader
    ##
    # Nokogiri implementation of an HTML parser.
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

      # Proxy class to implement uniform element accessors
      class NodeProxy
        attr_reader :node
        attr_reader :parent

        def initialize(node, parent = nil)
          @node = node
          @parent = parent
        end

        ##
        # Element language
        #
        # From HTML5 3.2.3.3
        #   If both the lang attribute in no namespace and the lang attribute in the XML namespace are set
        #   on an element, user agents must use the lang attribute in the XML namespace, and the lang
        #   attribute in no namespace must be ignored for the purposes of determining the element's
        #   language.
        #
        # @return [String]
        def language
          language = case
          when @node.document.is_a?(::Nokogiri::XML::Document) && @node.attributes["xml:lang"]
            @node.attributes["xml:lang"].to_s
          when @node.document.is_a?(::Nokogiri::XML::Document) && @node.attributes["lang"]
            @node.attributes["lang"].to_s
          when @node.attribute("lang")
            @node.attribute("lang").to_s
          else
            parent && parent.element? && parent.language
          end
        end

        ##
        # Get any xml:base in effect for this element
        def base
          if @base.nil?
            @base = attributes['xml:base'] ||
            (parent && parent.element? && parent.base) ||
            false
          end

          @base == false ? nil : @base
        end

        def display_path
          @display_path ||= begin
            path = []
            path << parent.display_path if parent
            path << @node.name
            case @node
            when ::Nokogiri::XML::Element then path.join("/")
            when ::Nokogiri::XML::Attr    then path.join("@")
            else path.join("?")
            end
          end
        end

        ##
        # Return true of all child elements are text
        #
        # @return [Array<:text, :element, :attribute>]
        def text_content?
          @node.children.all? {|c| c.text?}
        end

        ##
        # Retrieve XMLNS definitions for this element
        #
        # @return [Hash{String => String}]
        def namespaces
          @node.namespace_definitions.inject({}) {|memo, ns| memo[ns.prefix] = ns.href.to_s; memo }
        end
        
        ##
        # Children of this node
        #
        # @return [NodeSetProxy]
        def children
          NodeSetProxy.new(@node.children, self)
        end

        ##
        # Elements of this node
        #
        # @return [NodeSetProxy]
        def elements
          NodeSetProxy.new(@node.elements, self)
        end

        ##
        # Rational debug output
        def to_str
          @node.path
        end

        ##
        # Proxy for everything else to @node
        def method_missing(method, *args)
          @node.send(method, *args)
        end
      end

      ##
      # NodeSet proxy
      class NodeSetProxy
        attr_reader :node_set
        attr_reader :parent

        def initialize(node_set, parent)
          @node_set = node_set
          @parent = parent
        end

        ##
        # Return a proxy for each child
        #
        # @yield child
        # @yieldparam [NodeProxy] child
        def each
          @node_set.each do |c|
            yield NodeProxy.new(c, parent)
          end
        end

        ##
        # Return proxy for first element and remove it
        # @return [NodeProxy]
        def shift
          (e = node_set.shift) && NodeProxy.new(e, parent)
        end

        ##
        # Add NodeSetProxys
        # @param [NodeSetProxy, Nokogiri::XML::Node] other
        # @return [NodeSetProxy]
        def +(other)
          NodeSetProxy.new(self.node_set + other.node_set, parent)
        end

        ##
        # Add a NodeProxy
        # @param [NodeProxy, Nokogiri::XML::Node] elem
        # @return [NodeSetProxy]
        def <<(elem)
          node_set << (elem.is_a?(NodeProxy) ? elem.node : elem)
          self
        end

        def inspect
          @node_set.map {|c| NodeProxy.new(c, parent).display_path}.inspect
        end

        ##
        # Proxy for everything else to @node_set
        def method_missing(method, *args)
          @node_set.send(method, *args)
        end
      end

      ##
      # Initializes the underlying XML library.
      #
      # @param  [Hash{Symbol => Object}] options
      # @return [void]
      def initialize_html(input, **options)
        require 'nokogiri' unless defined?(::Nokogiri)
        @doc = case input
        when ::Nokogiri::XML::Document
          input
        else
          # Try to detect charset from input
          options[:encoding] ||= input.charset if input.respond_to?(:charset)
          
          # Otherwise, default is utf-8
          options[:encoding] ||= 'utf-8'
          options[:encoding] = options[:encoding].to_s if options[:encoding]

          begin
            input = input.read if input.respond_to?(:read)
            ::Nokogiri::HTML5(input.force_encoding(options[:encoding]), max_parse_errors: 1000)
          rescue LoadError, NoMethodError
            ::Nokogiri::HTML.parse(input, base_uri.to_s, options[:encoding])
          end
        end
      end

      # Accessor methods to mask native elements & attributes
      
      ##
      # Return proxy for document root
      def root
        @root ||= NodeProxy.new(@doc.root) if @doc && @doc.root
      end
      
      ##
      # Document errors
      def doc_errors
        @doc.errors.reject do |e|
          e.to_s =~ %r{(The doctype must be the first token in the document)|(Expected a doctype token)|(Unexpected '\?' where start tag name is expected)}
        end
      end
      
      ##
      # Find value of document base
      #
      # @param [String] base Existing base from URI or :base_uri
      # @return [String]
      def doc_base(base)
        # find if the document has a base element
        base_el = @doc.at_css("html>head>base") 
        base = base_el.attribute("href").to_s.split("#").first if base_el
        base
      end

      ##
      # Based on Microdata element.getItems
      #
      # @see https://www.w3.org/TR/2011/WD-microdata-20110525/#top-level-microdata-items
      def getItems
        @doc.css('[itemscope]').select {|el| !el.has_attribute?('itemprop')}.map {|n| NodeProxy.new(n)}
      end
      
      ##
      # Look up an element in the document by id
      def find_element_by_id(id)
        (e = @doc.at_css("##{id}")) && NodeProxy.new(e)
      end
    end
  end
end
