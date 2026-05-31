require 'htmlentities'

module RDF::RDFXML
  class Reader < RDF::Reader
    ##
    # REXML implementation of an XML parser.
    #
    # @see http://www.germane-software.com/software/rexml/
    module REXML
      ##
      # Returns the name of the underlying XML library.
      #
      # @return [Symbol]
      def self.library
        :rexml
      end

      # For Attribute namespaces
      Namespace = Struct.new(:href, :prefix) do
        def to_s; href; end
      end

      # Proxy class to implement uniform element accessors
      class NodeProxy
        attr_reader :node
        attr_reader :parent

        def initialize(node, parent = nil)
          @node = node
          @parent = parent
          @parent = NodeProxy.new(node.parent) if @parent.nil? &&
                                                  node.respond_to?(:parent) &&
                                                  node.parent &&
                                                  !node.parent.is_a?(::REXML::Document)
        end

        # Create a new element child of an existing node
        def create_node(name, children)
          native = ::REXML::Element.new(name, @node)
          children.each do |c|
            case c.node
            when ::REXML::Text
              native.add_text(c.node)
            when ::REXML::Element
              native.add_element(c.node)
            when ::REXML::Comment
              # Skip comments
            else
              raise "Unexpected child node type: #{c.node.class}"
            end
          end
          NodeProxy.new(native, self)
        end

        ##
        # Element language
        #
        # @return [String]
        def language
          @node.attribute("lang", RDF::XML.to_s)
        end

        ##
        # Return xml:base on element, if defined
        #
        # @return [String]
        def base
          if @base.nil?
            @base = attributes['xml:base'] ||
            (parent && parent.element? && parent.base) ||
            false
          end

          @base == false ? nil : @base
        end

        def attribute_with_ns(name, namespace)
          @node.attribute(name, namespace)
        end

        def display_path
          @display_path ||= begin
            path = []
            path << parent.display_path if parent
            path << @node.name
            case @node
            when ::REXML::Element   then path.join("/")
            when ::REXML::Attribute then path.join("@")
            else path.join("?")
            end
          end
        end

        # URI of namespace + name
        def uri
          ns = namespace || RDF::XML.to_s
          ns = ns.href if ns.respond_to?(:href)
          RDF::URI.intern(ns + @node.name)
        end

        ##
        # Return true of all child elements are text
        #
        # @return [Array<:text, :element, :attribute>]
        def text_content?
          @node.children.all? {|c| c.is_a?(::REXML::Text)}
        end

        ##
        # Retrieve XMLNS definitions for this element
        #
        # @return [Hash{String => String}]
        def namespaces
          ns_decls = {}
          @node.attributes.each do |name, attr|
            next unless name =~ /^xmlns(?:\:(.+))?/
            ns_decls[$1] = attr
          end
          ns_decls
        end

        def namespace
          Namespace.new(@node.namespace, @node.prefix) unless @node.namespace.to_s.empty?
        end

        def add_namespace(prefix, uri)
          prefix ? !@node.add_namespace(prefix, uri) : @node.add_namespace(uri)
        end

        ##
        # Children of this node
        #
        # @return [NodeSetProxy]
        def children
          NodeSetProxy.new(@node.children, self)
        end

        # Ancestors of this element, in order
        def ancestors
          @ancestors ||= parent ? parent.ancestors + [parent] : []
        end

        ##
        # Inner text of an element
        #
        # @see http://apidock.com/ruby/REXML/Element/get_text#743-Get-all-inner-texts
        # @return [String]
        def inner_text
          coder = HTMLEntities.new
          ::REXML::XPath.match(@node,'.//text()').map { |e|
            coder.decode(e)
          }.join
        end

        def attribute_nodes
          attrs = @node.attributes.dup.keep_if do |name, attr|
            !name.start_with?('xmlns')
          end
          @attribute_nodes ||= (attrs.empty? ? attrs : NodeSetProxy.new(attrs, self))
        end

        def remove_attribute(key)
          @node.delete_attribute(key)
        end

        def xpath(*args)
          #NodeSetProxy.new(::REXML::XPath.match(@node, path, namespaces), self)
          ::REXML::XPath.match(@node, *args).map do |n|
            NodeProxy.new(n, parent)
          end
        end

        def at_xpath(*args)
          xpath(*args).first
        end

        ##
        # Node type accessors
        #
        # @return [Boolean]
        def text?
          @node.is_a?(::REXML::Text)
        end

        def element?
          @node.is_a?(::REXML::Element)
        end

        def blank?
          @node.is_a?(::REXML::Text) && @node.empty?
        end

        def to_s; @node.to_s; end

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
        # @yieldparam [NodeProxy]
        def each
          @node_set.to_a.each do |c|
            yield NodeProxy.new(c, parent)
          end
        end
        
        ##
        # Return selected NodeProxies based on selection
        #
        # @yield child
        # @yieldparam [NodeProxy]
        # @return [Array[NodeProxy]]
        def select
          @node_set.to_a.map {|n| NodeProxy.new(n, parent)}.select do |c|
            yield c
          end
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
      def initialize_xml(input, **options)
        require 'rexml/document' unless defined?(::REXML)
        @doc = case input
        when ::REXML::Document
          input
        else
          # Try to detect charset from input
          options[:encoding] ||= input.charset if input.respond_to?(:charset)
          
          # Otherwise, default is utf-8
          options[:encoding] ||= 'utf-8'

          # Set xml:base for the document element, if defined
          @base_uri = base_uri ? base_uri.to_s : nil

          # Only parse as XML, no HTML mode
          ::REXML::Document.new(input.respond_to?(:read) ? input.read : input.to_s)
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
        []
      end
    end
  end
end
