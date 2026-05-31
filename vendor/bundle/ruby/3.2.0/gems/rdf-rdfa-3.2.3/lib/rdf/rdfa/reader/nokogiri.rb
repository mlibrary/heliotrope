module RDF::RDFa
  class Reader < RDF::Reader
    ##
    # Nokogiri implementation of an XML parser.
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
          case
          when @node.attribute_with_ns("lang", "http://www.w3.org/XML/1998/namespace")
            @node.attribute_with_ns("lang", "http://www.w3.org/XML/1998/namespace")
          when @node.attribute("xml:lang")
            @node.attribute("xml:lang").to_s
          when @node.attribute("lang")
            @node.attribute("lang").to_s
          end
        end

        ##
        # Return xml:base on element, if defined
        #
        # @return [String]
        def base
          @node.attribute_with_ns("base", "http://www.w3.org/XML/1998/namespace") || @node.attribute('xml:base')
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

        # Ancestors of this element, in order
        def ancestors
          @ancestors ||= parent ? parent.ancestors + [parent] : []
        end

        ##
        # Inner text of an element. Decode Entities
        #
        # @return [String]
        #def inner_text
        #  coder = HTMLEntities.new
        #  coder.decode(@node.inner_text)
        #end

        def attribute_nodes
          @attribute_nodes ||= NodeSetProxy.new(@node.attribute_nodes, self)
        end

        def xpath(*args)
          @node.xpath(*args).map do |n|
            # Get node ancestors
            parent = n.ancestors.reverse.inject(nil) do |p,node|
              NodeProxy.new(node, p)
            end
            NodeProxy.new(n, parent)
          end
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
        # @yieldparam [NodeProxy]
        def each
          @node_set.each do |c|
            yield NodeProxy.new(c, parent)
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
        require 'nokogiri' unless defined?(::Nokogiri)
        @doc = case input
        when ::Nokogiri::HTML::Document, ::Nokogiri::XML::Document
          input
        else
          # Try to detect charset from input
          options[:encoding] ||= input.charset if input.respond_to?(:charset)

          # Otherwise, default is utf-8
          options[:encoding] ||= 'utf-8'
          options[:encoding] = options[:encoding].to_s if options[:encoding]

          case @host_language
          when :html4
            ::Nokogiri::HTML.parse(input, base_uri.to_s, options[:encoding])
          when :html5
            begin
              input = input.read if input.respond_to?(:read)
              ::Nokogiri::HTML5(input.force_encoding(options[:encoding]), max_parse_errors: 1000)
            rescue LoadError, NoMethodError
              ::Nokogiri::HTML.parse(input, base_uri.to_s, options[:encoding])
            end
          else
            ::Nokogiri::XML.parse(input, base_uri.to_s, options[:encoding])
          end
        end
      end

      # Determine the host language and/or version from options and the input document
      def detect_host_language_version(input, **options)
        @host_language = options[:host_language] ? options[:host_language].to_sym : nil
        @version = options[:version] ? options[:version].to_sym : nil
        return if @host_language && @version

        # Snif version based on input
        case input
        when ::Nokogiri::XML::Document, ::Nokogiri::HTML::Document
          doc_type_string = input.children.detect {|c| c.is_a?(::Nokogiri::XML::DTD)}
          version_attr = input.root && input.root.attribute("version").to_s
          root_element = input.root.name.downcase
          content_type = case
          when root_element == "html" && input.is_a?(::Nokogiri::HTML::Document)
            "text/html"
          when root_element == "html" && input.is_a?(::Nokogiri::XML::Document)
            "application/xhtml+html"
          end
        else
          content_type = input.content_type if input.respond_to?(:content_type)

          # Determine from head of document
          head = if input.respond_to?(:read)
            input.rewind
            string = input.read(1000)
            input.rewind
            string.to_s
          else
            input.to_s[0..1000]
          end

          doc_type_string = head.match(%r(<!DOCTYPE[^>]*>)m).to_s
          root = head.match(%r(<[^!\?>]*>)m).to_s
          root_element = root.match(%r(^<(\S+)[ >])) ? $1 : ""
          version_attr = root.match(/version\s*=\s*"([^"]+)"/m) ? $1 : ""
          head_element = head.match(%r(<head.*<\/head>)mi)
          head_doc = ::Nokogiri::HTML.parse(head_element.to_s)

          # May determine content-type and/or charset from meta
          # Easist way is to parse head into a document and iterate
          # of CSS matches
          head_doc.css("meta").each do |e|
            if e.attr("http-equiv").to_s.downcase == 'content-type'
              content_type, e = e.attr("content").to_s.downcase.split(";")
              options[:encoding] = $1.downcase if e.to_s =~ /charset=([^\s]*)$/i
            elsif e.attr("charset")
              options[:encoding] = e.attr("charset").to_s.downcase
            end
          end
        end

        # Already using XML parser, determine from DOCTYPE and/or root element
        @version ||= :"rdfa1.0" if doc_type_string =~ /RDFa 1\.0/
        @version ||= :"rdfa1.0" if version_attr =~ /RDFa 1\.0/
        @version ||= :"rdfa1.1" if version_attr =~ /RDFa 1\.1/
        @version ||= :"rdfa1.1"

        @host_language ||= :xhtml1 if @version == :"rdfa1.0" && doc_type_string =~ /html/i

        @host_language ||= case content_type
        when "application/xml"  then :xml
        when "image/svg+xml"    then :svg
        when "text/html"
          case doc_type_string
          when /html 4/i        then :html4
          when /xhtml/i         then :xhtml1
          when /html/i          then :html5
          else                       :html5
          end
        when "application/xhtml+xml"
          case doc_type_string
          when /html 4/i        then :html4
          when /xhtml/i         then :xhtml1
          when /html/i          then :xhtml5
          else                       :xhtml5
          end
        else
          case root_element
          when /svg/i           then :svg
          else                       :html5
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
        if @host_language == :html5
          @doc.errors.reject do |e|
            e.to_s =~ %r{(The doctype must be the first token in the document)|(Expected a doctype token)|(Unexpected '\?' where start tag name is expected)}
          end
        else
          @doc.errors.reject {|e| e.to_s =~ /(?:Tag \w+ invalid)|(?:Missing attribute name)/}
        end
      end

      ##
      # Find value of document base
      #
      # @param [String] base Existing base from URI or :base_uri
      # @return [String]
      def doc_base(base)
        # find if the document has a base element
        case @host_language
        when :xhtml1, :xhtml5, :html4, :html5
          base_el = @doc.at_css("html>head>base")
          base = base.join(base_el.attribute("href").to_s.split("#").first) if base_el
        else
          xml_base = root.attribute_with_ns("base", "http://www.w3.org/XML/1998/namespace") || root.attribute('xml:base') if root
          base = base.join(xml_base) if xml_base
        end

        base
      end
    end
  end
end
