begin
  require 'nokogiri'
rescue LoadError
  :rexml
end
require 'rdf/xsd'

module RDF::RDFXML
  ##
  # An RDF/XML parser in Ruby
  #
  # Based on RDF/XML Syntax Specification: http://www.w3.org/TR/REC-rdf-syntax/
  #
  # Extension: A nodeElement can also use the rdf:resource attribute, if none of the other standard attributes are defined.
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class Reader < RDF::Reader
    format Format
    include RDF::Util::Logger

    CORE_SYNTAX_TERMS = %w(RDF ID about parseType resource nodeID datatype).map {|n| "http://www.w3.org/1999/02/22-rdf-syntax-ns##{n}"}
    OLD_TERMS = %w(aboutEach aboutEachPrefix bagID).map {|n| "http://www.w3.org/1999/02/22-rdf-syntax-ns##{n}"}

    # The Recursive Baggage
    # @private
    class EvaluationContext
      attr_reader :base
      attr_accessor :subject
      attr_accessor :uri_mappings
      attr_accessor :language
      attr_accessor :graph
      attr_accessor :li_counter

      def initialize(base, element, graph, &cb)
        # Initialize the evaluation context, [5.1]
        self.base = RDF::URI(base)
        @uri_mappings = {}
        @language = nil
        @graph = graph
        @li_counter = 0

        extract_from_element(element, &cb) if element
      end
      
      # Clone existing evaluation context adding information from element
      def clone(element, **options, &cb)
        new_ec = EvaluationContext.new(@base, nil, @graph)
        new_ec.uri_mappings = self.uri_mappings.clone
        new_ec.language = self.language

        new_ec.extract_from_element(element, &cb) if element
        
        options.each_pair {|k, v| new_ec.send("#{k}=", v)}
        new_ec
      end
      
      # Extract Evaluation Context from an element by looking at ancestors recurively
      def extract_from_ancestors(el, &cb)
        ancestors = el.ancestors
        while ancestors.length > 0
          a = ancestors.pop
          next unless a.element?
          extract_from_element(a, &cb)
        end
        extract_from_element(el, &cb)
      end

      # Extract Evaluation Context from an element
      def extract_from_element(el, &cb)
        self.language = el.language if el.language
        if b = el.base
          b = RDF::URI(b)
          self.base = b.absolute? ? b : self.base.join(b)
        end
        self.uri_mappings.merge!(extract_mappings(el, &cb))
      end
      
      # Extract the XMLNS mappings from an element
      def extract_mappings(element, &cb)
        mappings = {}

        # look for xmlns
        element.namespaces.each do |prefix, value|
          value = base.join(value)
          mappings[prefix] = value
          cb.call(prefix, value) if block_given?
        end
        mappings
      end
      
      # Produce the next list entry for this context
      def li_next
        @li_counter += 1
        RDF["_#{@li_counter}"]
      end

      # Set XML base. Ignore any fragment
      def base=(b)
        @base = RDF::URI.intern(b.to_s.split('#').first)
      end

      def inspect
        v = %w(base subject language).map {|a| "#{a}='#{self.send(a).nil? ? 'nil' : self.send(a)}'"}
        v << "uri_mappings[#{uri_mappings.keys.length}]"
        v.join(",")
      end
    end

    # Returns the XML implementation module for this reader instance.
    #
    # @!attribute [r] implementation
    # @return [Module]
    attr_reader :implementation

    ##
    # Initializes the RDF/XML reader instance.
    #
    # @param  [Nokogiri::XML::Document, IO, File, String] input
    #   the input stream to read
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Symbol] :library
    #   One of :nokogiri or :rexml. If nil/unspecified uses :nokogiri if available, :rexml otherwise.
    # @option options [Encoding] :encoding     (Encoding::UTF_8)
    #   the encoding of the input stream (Ruby 1.9+)
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize parsed literals
    # @option options [Boolean]  :intern       (true)
    #   whether to intern all parsed URIs
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (not supported by all readers)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs
    # @return [reader]
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [Error] Raises RDF::ReaderError if _validate_
    def initialize(input = $stdin, **options, &block)
      super do
        @library = case options[:library]
        when nil
          # Use Nokogiri when available, and REXML otherwise:
          defined?(::Nokogiri) ? :nokogiri : :rexml
        when :nokogiri, :rexml
          options[:library]
        else
          log_fatal("expected :rexml or :nokogiri, but got #{options[:library].inspect}", exception: ArgumentError)
        end

        require "rdf/rdfxml/reader/#{@library}"
        @implementation = case @library
          when :nokogiri then Nokogiri
          when :rexml    then REXML
        end
        self.extend(@implementation)

        input.rewind if input.respond_to?(:rewind)
        initialize_xml(input, **options) rescue log_fatal($!.message)

        if root.nil?
          log_info("Empty document")
        elsif !doc_errors.empty?
          log_error("Synax errors") {doc_errors}
        end

        block.call(self) if block_given?
      end
    end

    # No need to rewind, as parsing is done in initialize
    def rewind; end
    
    # Document closed when read in initialize
    def close; end
    
    ##
    # Iterates the given block for each RDF statement in the input.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        # Block called from add_statement
        @callback = block
        return unless root

        log_fatal "root must be a proxy not a #{root.class}" unless root.is_a?(@implementation::NodeProxy)

        add_debug(root, "base_uri: #{base_uri.inspect}")
      
        rdf_nodes = root.xpath("//rdf:RDF", "rdf" => RDF.to_uri.to_s)
        if rdf_nodes.size == 0
          # If none found, root element may be processed as an RDF Node

          ec = EvaluationContext.new(base_uri, root, @graph) do |prefix, value|
            prefix(prefix, value)
          end

          nodeElement(root, ec)
        else
          rdf_nodes.each do |node|
            log_fatal "node must be a proxy not a #{node.class}" unless node.is_a?(@implementation::NodeProxy)
            # XXX Skip this element if it's contained within another rdf:RDF element

            # Extract base, lang and namespaces from parents to create proper evaluation context
            ec = EvaluationContext.new(base_uri, nil, @graph)
            ec.extract_from_ancestors(node) do |prefix, value|
              prefix(prefix, value)
            end
            node.children.each {|el|
              next unless el.element?
              log_fatal "el must be a proxy not a #{el.class}" unless el.is_a?(@implementation::NodeProxy)
              new_ec = ec.clone(el) do |prefix, value|
                prefix(prefix, value)
              end
              nodeElement(el, new_ec)
            }
          end
        end

        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_for(:each_statement)
    end

    ##
    # Iterates the given block for each RDF triple in the input.
    #
    # @yield  [subject, predicate, object]
    # @yieldparam [RDF::Resource] subject
    # @yieldparam [RDF::URI]      predicate
    # @yieldparam [RDF::Value]    object
    # @return [void]
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end
    
    private

    # Keep track of allocated BNodes
    def bnode(value = nil)
      @bnode_cache ||= {}
      @bnode_cache[value.to_s] ||= RDF::Node.new(value)
    end
    
    # Figure out the document path, if it is a Nokogiri::XML::Element or Attribute
    def node_path(node)
      "<#{base_uri}>#{node.respond_to?(:display_path) ? node.display_path : node}"
    end
    
    # Log a debug message
    #
    # @param [Nokogiri::XML::Node, #to_s] node XML Node or string for showing context
    # @param [String] message
    # @yieldreturn [String] appended to message, to allow for lazy-evaulation of message
    def add_debug(node, message = "", &block)
      log_debug(node_path(node), message, &block)
    end

    # Log an error message
    #
    # @param [Nokogiri::XML::Node, #to_s] node XML Node or string for showing context
    # @param [String] message
    # @yieldreturn [String] appended to message, to allow for lazy-evaulation of message
    def add_error(node, message = "", &block)
      log_error(node_path(node), message, &block)
    end

    # add a statement, object can be literal or URI or bnode
    #
    # @param [Nokogiri::XML::Node, any] node XML Node or string for showing context
    # @param [URI, BNode] subject the subject of the statement
    # @param [URI] predicate the predicate of the statement
    # @param [URI, BNode, Literal] object the object of the statement
    # @return [Statement] Added statement
    # @raise [RDF::ReaderError] Checks parameter types and raises if they are incorrect if validating.
    def add_triple(node, subject, predicate, object)
      statement = RDF::Statement(subject, predicate, object)
      add_debug(node) {"statement: #{statement}"}
      @callback.call(statement)
    end

    # XML nodeElement production
    #
    # @param [XML Element] el XMl Element to parse
    # @param [EvaluationContext] ec Evaluation context
    # @return [RDF::URI] subject The subject found for the node
    # @raise [RDF::ReaderError] Raises Exception if validating
    def nodeElement(el, ec)
      log_fatal "el must be a proxy not a #{el.class}" unless el.is_a?(@implementation::NodeProxy)
      # subject
      subject = ec.subject || parse_subject(el, ec)
      
      add_debug(el) {"nodeElement, ec: #{ec.inspect}"}
      add_debug(el) {"nodeElement, el: #{el.uri}"}
      add_debug(el) {"nodeElement, subject: #{subject.nil? ? 'nil' : subject.to_s}"}

      unless el.uri.to_s == RDF.Description.to_s
        add_triple(el, subject, RDF.type, el.uri)
      end

      # produce triples for attributes
      el.attribute_nodes.each do |attr|
        add_debug(el) {"propertyAttr: #{attr.uri}='#{attr.value}'"}
        if attr.uri.to_s == RDF.type.to_s
          # If there is an attribute a in propertyAttr with a.URI == rdf:type
          # then u:=uri(identifier:=resolve(a.string-value))
          # and the following triple is added to the graph:
          u = uri(ec.base, attr.value)
          add_triple(attr, subject, RDF.type, u)
        elsif is_propertyAttr?(attr)
          # Attributes not RDF.type
          predicate = attr.uri
          lit = RDF::Literal.new(attr.value, language: ec.language, validate: validate?, canonicalize: canonicalize?)
          add_triple(attr, subject, predicate, lit)
        end
      end
      
      # Handle the propertyEltList children events in document order
      el.children.each do |child|
        log_fatal "child must be a proxy not a #{child.class}" unless child.is_a?(@implementation::NodeProxy)
        next unless child.element?
        child_ec = ec.clone(child) do |prefix, value|
          prefix(prefix, value)
        end
        predicate = child.uri
        add_debug(child) {"propertyElt, predicate: #{predicate}"}
        propertyElementURI_check(child)
        
        # Determine the content type of this property element
        log_fatal "child must be a proxy not a #{child.class}" unless child.is_a?(@implementation::NodeProxy)

        text_nodes = child.children.select(&:text?)
        element_nodes = child.children.select(&:element?)
        add_debug(child) {"#{text_nodes.to_a.length} text nodes, #{element_nodes.to_a.length} element nodes"}

        text_nodes.each do |node|
          log_fatal "text node must be a proxy not a #{node.class}" unless node.is_a?(@implementation::NodeProxy)
        end
        element_nodes.each do |node|
          log_fatal "element node must be a proxy not a #{node.class}" unless node.is_a?(@implementation::NodeProxy)
        end

        if element_nodes.size > 1
          element_nodes.each do |node|
            add_debug(child) {"  node: #{node.to_s}"}
          end
        end
        
        # List expansion
        predicate = ec.li_next if predicate == RDF.li
        
        # Productions based on set of attributes
        
        # All remaining reserved XML Names (See Name in XML 1.0) are now removed from the set.
        # These are, all attribute information items in the set with property [prefix] beginning with xml
        # (case independent comparison) and all attribute information items with [prefix] property having
        # no value and which have [local name] beginning with xml (case independent comparison) are removed.
        # Note that the [base URI] accessor is computed by XML Base before any xml:base attribute information item
        # is deleted.
        attrs = {}
        id = datatype = parseType = resourceAttr = nodeID = nil
        
        child.attribute_nodes.each do |attr|
          if attr.namespace.to_s.empty?
            # The support for a limited set of non-namespaced names is REQUIRED and intended to allow
            # RDF/XML documents specified in [RDF-MS] to remain valid;
            # new documents SHOULD NOT use these unqualified attributes and applications
            # MAY choose to warn when the unqualified form is seen in a document.
            add_debug(el) {"Unqualified attribute '#{attr}'"}
            #attrs[attr.to_s] = attr.value unless attr.to_s.match?(/^xml/)
          elsif attr.namespace.href == RDF::XML.to_s
            # No production. Lang and base elements already extracted
          elsif attr.namespace.href == RDF.to_uri.to_s
            case attr.name
            when "ID"         then id = attr.value
            when "datatype"   then datatype = attr.value
            when "parseType"  then parseType = attr.value
            when "resource"   then resourceAttr = attr.value
            when "nodeID"     then nodeID = attr.value
            else                   attrs[attr] = attr.value
            end
          else
            attrs[attr] = attr.value
          end
        end
        
        add_error(el, "Cannot have rdf:nodeID and rdf:resource.") if nodeID && resourceAttr

        # Apply character transformations
        id = id_check(el, RDF::NTriples.unescape(id), nil) if id
        resourceAttr = RDF::NTriples.unescape(resourceAttr) if resourceAttr
        nodeID = nodeID_check(el, RDF::NTriples.unescape(nodeID)) if nodeID

        add_debug(child) {"attrs: #{attrs.inspect}"}
        add_debug(child) {"datatype: #{datatype}"} if datatype
        add_debug(child) {"parseType: #{parseType}"} if parseType
        add_debug(child) {"resource: #{resourceAttr}"} if resourceAttr
        add_debug(child) {"nodeID: #{nodeID}"} if nodeID
        add_debug(child) {"id: #{id}"} if id
        
        if attrs.empty? && datatype.nil? && parseType.nil? && element_nodes.size == 1
          # Production resourcePropertyElt

          new_ec = child_ec.clone(nil) do |prefix, value|
            prefix(prefix, value)
          end
          new_node_element = element_nodes.first
          log_fatal "new_node_element must be a proxy not a #{new_node_element.class}" unless new_node_element.is_a?(@implementation::NodeProxy)
          add_debug(child) {"resourcePropertyElt: #{node_path(new_node_element)}"}
          new_subject = nodeElement(new_node_element, new_ec)
          add_triple(child, subject, predicate, new_subject)
        elsif attrs.empty? && parseType.nil? && element_nodes.size == 0 && text_nodes.size > 0
          # Production literalPropertyElt
          add_debug(child, "literalPropertyElt")
          
          literal_opts = {validate: validate?, canonicalize: canonicalize?}
          if datatype
            literal_opts[:datatype] = uri(datatype)
          else
            literal_opts[:language] = child_ec.language
          end
          literal = RDF::Literal.new(child.inner_text, **literal_opts)
          add_triple(child, subject, predicate, literal)
          reify(id, child, subject, predicate, literal, ec) if id
        elsif parseType == "Resource"
          # Production parseTypeResourcePropertyElt
          add_debug(child, "parseTypeResourcePropertyElt")

          unless attrs.empty?
            add_error(child, "Resource Property with extra attributes") {attrs.inspect}
          end

          # For element e with possibly empty element content c.
          n = RDF::Node.new
          add_triple(child, subject, predicate, n)

          # Reification
          reify(id, child, subject, predicate, n, child_ec) if id
          
          # If the element content c is not empty, then use event n to create a new sequence of events as follows:
          #
          # start-element(URI := rdf:Description,
          #     subject := n,
          #     attributes := set())
          # c
          # end-element()
          add_debug(child, "compose new sequence with rdf:Description")
          #child.clone
          #node.attributes.keys.each {|a| node.remove_attribute(a)}
          node = el.create_node("Description", child.children)
          node.add_namespace(nil, RDF.to_uri.to_s)
          add_debug(node) { "uri: #{node.uri}, namespace: #{node.namespace.inspect}"}
          new_ec = child_ec.clone(nil, subject: n) do |prefix, value|
            prefix(prefix, value)
          end
          nodeElement(node, new_ec)
        elsif parseType == "Collection"
          # Production parseTypeCollectionPropertyElt
          add_debug(child, "parseTypeCollectionPropertyElt")

          unless attrs.empty?
            add_error(child, "Resource Property with extra attributes") {attrs.inspect}
          end

          # For element event e with possibly empty nodeElementList l. Set s:=list().
          # For each element event f in l, n := bnodeid(identifier := generated-blank-node-id()) and append n to s to give a sequence of events.
          s = element_nodes.map { RDF::Node.new }
          n = s.first || RDF["nil"]
          add_triple(child, subject, predicate, n)
          reify(id, child, subject, predicate, n, child_ec) if id
          
          # Add first/rest entries for all list elements
          s.each_index do |i|
            n = s[i]
            o = s[i+1]
            f = element_nodes[i]

            new_ec = child_ec.clone(nil) do |prefix, value|
              prefix(prefix, value)
            end
            object = nodeElement(f, new_ec)
            add_triple(child, n, RDF.first, object)
            add_triple(child, n, RDF.rest, o ? o : RDF.nil)
          end
        elsif parseType   # Literal or Other
          # Production parseTypeResourcePropertyElt
          add_debug(child, parseType == "Literal" ? "parseTypeResourcePropertyElt" : "parseTypeOtherPropertyElt (#{parseType})")

          unless attrs.empty?
            add_error(child, "Resource Property with extra attributes") {attrs.inspect}
          end

          if resourceAttr
            add_error(child, "illegal rdf:resource") {resourceAttr.inspect}
          end

          begin
            c14nxl = child.children.c14nxl(
              library: @library,
              language: ec.language,
              namespaces: child_ec.uri_mappings)
            object = RDF::Literal.new(c14nxl,
              library: @library,
              datatype: RDF.XMLLiteral,
              validate: validate?,
              canonicalize: canonicalize?)

            add_triple(child, subject, predicate, object)
          rescue ArgumentError => e
            add_error(child, e.message)
          end
        elsif text_nodes.size == 0 && element_nodes.size == 0
          # Production emptyPropertyElt
          add_debug(child, "emptyPropertyElt")

          if attrs.empty? && resourceAttr.nil? && nodeID.nil?
            
            literal = RDF::Literal.new("", language: ec.language)
            add_triple(child, subject, predicate, literal)
            
            # Reification
            reify(id, child, subject, predicate, literal, child_ec) if id
          else
            resource = if resourceAttr
              uri(ec.base, resourceAttr)
            elsif nodeID
              bnode(nodeID)
            else
              RDF::Node.new
            end

            # produce triples for attributes
            attrs.each_pair do |attr, val|
              add_debug(el) {"attr: #{attr.name}='#{val}'"}
              
              if attr.uri.to_s == RDF.type.to_s
                add_triple(child, resource, RDF.type, val)
              else
                # Check for illegal attributes
                next unless is_propertyAttr?(attr)

                # Attributes not in RDF.type
                lit = RDF::Literal.new(val, language: child_ec.language)
                add_triple(child, resource, attr.uri, lit)
              end
            end
            add_triple(child, subject, predicate, resource)
            
            # Reification
            reify(id, child, subject, predicate, resource, child_ec) if id
          end
        end
      end
      
      # Return subject
      subject
    end
    
    private
    # Reify subject, predicate, and object given the EvaluationContext (ec) and current XMl element (el)
    def reify(id, el, subject, predicate, object, ec)
      add_debug(el, "reify, id: #{id}")
      rsubject = ec.base.join("#" + id)
      add_triple(el, rsubject, RDF.subject, subject)
      add_triple(el, rsubject, RDF.predicate, predicate)
      add_triple(el, rsubject, RDF.object, object)
      add_triple(el, rsubject, RDF.type, RDF["Statement"])
    end

    # Figure out the subject from the element.
    def parse_subject(el, ec)
      old_property_check(el)
      
      nodeElementURI_check(el)
      about = el.attribute_with_ns("about", RDF.to_uri.to_s)
      id = el.attribute_with_ns("ID", RDF.to_uri.to_s)
      nodeID = el.attribute_with_ns("nodeID", RDF.to_uri.to_s)
      resource = el.attribute_with_ns("resource", RDF.to_uri.to_s)
      
      if nodeID && about
        add_error(el, "Cannot have rdf:nodeID and rdf:about.")
      elsif nodeID && id
        add_error(el, "Cannot have rdf:nodeID and rdf:ID.")
      end

      case
      when id
        add_debug(el) {"parse_subject, id: #{RDF::NTriples.unescape(id.value).inspect}"}
        id_check(el, RDF::NTriples.unescape(id.value), ec.base) # Returns URI
      when nodeID
        # The value of rdf:nodeID must match the XML Name production
        nodeID = nodeID_check(el, RDF::NTriples.unescape(nodeID.value))
        add_debug(el) {"parse_subject, nodeID: #{nodeID.inspect}"}
        bnode(nodeID)
      when about
        about = RDF::NTriples.unescape(about.value)
        add_debug(el) {"parse_subject, about: #{about.inspect}"}
        uri(ec.base, about)
      when resource
        resource = RDF::NTriples.unescape(resource.value)
        add_debug(el) {"parse_subject, resource: #{resource.inspect}"}
        uri(ec.base, resource)
      else
        add_debug(el, "parse_subject, BNode")
        RDF::Node.new
      end
    end
    
    # ID attribute must be an NCName
    def id_check(el, id, base)
      add_error(el, "ID addtribute '#{id}' must be a NCName") unless NC_REGEXP.match(id)

      # ID may only be specified once for the same URI
      if base
        uri = uri(base, "##{id}")
        add_error(el, "ID addtribute '#{id}' may only be defined once for the same URI") if prefix(id) && RDF::URI(prefix(id)) == uri
        
        RDF::URI(prefix(id, uri))
        # Returns URI, in this case
      else
        id
      end
    end
    
    # nodeID must be an XML Name
    # nodeID must pass Production rdf-id
    def nodeID_check(el, nodeID)
      if NC_REGEXP.match(nodeID)
        nodeID
      else
        add_error(el, "nodeID addtribute '#{nodeID}' must be an XML Name")
        nil
      end
    end
    
    # Is this attribute a Property Attribute?
    def is_propertyAttr?(attr)
      if ([RDF.Description.to_s, RDF.li.to_s] + OLD_TERMS).include?(attr.uri.to_s)
        add_error(attr, "Invalid use of rdf:#{attr.name}")
        return false
      end
      !CORE_SYNTAX_TERMS.include?(attr.uri.to_s) && attr.namespace && attr.namespace.href != RDF::XML.to_s
    end
    
    # Check Node Element name
    def nodeElementURI_check(el)
      if (CORE_SYNTAX_TERMS + [RDF.li.to_s] + OLD_TERMS).include?(el.uri.to_s)
        add_error(el, "Invalid use of rdf:#{el.name}")
      end
    end

    # Check Property Element name
    def propertyElementURI_check(el)
      if (CORE_SYNTAX_TERMS + [RDF.Description.to_s] + OLD_TERMS).include?(el.uri.to_s)
        add_error(el, "Invalid use of rdf:#{el.name}")
      end
    end

    # Check for the use of an obsolete RDF property
    def old_property_check(el)
      el.attribute_nodes.each do |attr|
        if OLD_TERMS.include?(attr.uri.to_s)
          add_error(el) {"Obsolete attribute '#{attr.uri}'"}
        end
      end
    end
    
    def uri(value, append = nil)
      append = RDF::URI(append)
      value = RDF::URI(value)
      value = if append.absolute?
        value = append
      elsif append
        value = value.join(append)
      else
        value
      end
      value.validate! if validate?
      value.canonicalize! if canonicalize?
      value = RDF::URI.intern(value) if intern?
      value
    end

  end
end
