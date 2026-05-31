require_relative 'extensions'

module RDF::RDFXML
  ##
  # An RDF/XML serialiser in Ruby
  #
  # Note that the natural interface is to write a whole graph at a time.
  # Writing statements or Triples will create a graph to add them to
  # and then serialize the graph.
  #
  # The writer will add prefix definitions, and use them for creating @prefix definitions, and minting QNames
  #
  # @example Obtaining a RDF/XML writer class
  #   RDF::Writer.for(:rdf)         #=> RDF::RDFXML::Writer
  #   RDF::Writer.for("etc/test.rdf")
  #   RDF::Writer.for(file_name: "etc/test.rdf")
  #   RDF::Writer.for(file_extension: "rdf")
  #   RDF::Writer.for(content_type: "application/rdf+xml")
  #
  # @example Serializing RDF graph into an RDF/XML file
  #   RDF::RDFXML::Write.open("etc/test.rdf") do |writer|
  #     writer << graph
  #   end
  #
  # @example Serializing RDF statements into an RDF/XML file
  #   RDF::RDFXML::Writer.open("etc/test.rdf") do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Serializing RDF statements into an RDF/XML string
  #   RDF::RDFXML::Writer.buffer do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Creating @base and @prefix definitions in output
  #   RDF::RDFXML::Writer.buffer(base_uri: "http://example.com/", prefixes: {
  #       nil => "http://example.com/ns#",
  #       foaf: "http://xmlns.com/foaf/0.1/"}
  #   ) do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class Writer < RDF::Writer
    format RDF::RDFXML::Format
    include RDF::Util::Logger

    VALID_ATTRIBUTES = [:none, :untyped, :typed]

    # Defines rdf:type of subjects to be emitted at the beginning of the document.
    # @return [Array<URI>]
    attr :top_classes

    # @return [Graph] Graph of statements serialized
    attr_accessor :graph

    # @return [RDF::URI] Base URI used for relativizing URIs
    attr_accessor :base_uri

    ##
    # RDF/XML Writer options
    # @see https://ruby-rdf.github.io/rdf/RDF/Writer#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :attributes,
          datatype: %w(none untyped typed),
          on: ["--attributes ATTRIBUTES",  %w(none untyped typed)],
          description: "How to use XML attributes when serializing, one of :none, :untyped, :typed. The default is :none.") {|arg| arg.to_sym},
        RDF::CLI::Option.new(
          symbol: :default_namespace,
          datatype: RDF::URI,
          on: ["--default-namespace URI", :REQUIRED],
          description: "URI to use as default namespace, same as prefixes.") {|arg| RDF::URI(arg)},
        RDF::CLI::Option.new(
          symbol: :lang,
          datatype: String,
          on: ["--lang LANG", :REQUIRED],
          description: "Output as root xml:lang attribute, and avoid generation xml:lang, where possible.") {|arg| RDF::URI(arg)},
        RDF::CLI::Option.new(
          symbol: :max_depth,
          datatype: Integer,
          on: ["--max-depth"],
          description: "Maximum depth for recursively defining resources, defaults to 3.") {|arg| arg.to_i},
        RDF::CLI::Option.new(
          symbol: :stylesheet,
          datatype: RDF::URI,
          on: ["--stylesheet URI", :REQUIRED],
          description: "URI to use as @href for output stylesheet processing instruction.") {|arg| RDF::URI(arg)},
      ]
    end

    ##
    # Initializes the RDF/XML writer instance.
    #
    # @param  [IO, File] output
    #   the output stream
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Symbol]    :attributes   (nil)
    #   How to use XML attributes when serializing, one of :none, :untyped, :typed. The default is :none.
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when constructing relative URIs
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize literals when serializing
    # @option options [String]   :default_namespace (nil)
    #   URI to use as default namespace, same as prefix(nil)
    # @option options [#to_s]   :lang   (nil)
    #   Output as root xml:lang attribute, and avoid generation _xml:lang_ where possible
    # @option options [Integer]  :max_depth (10)
    #   Maximum depth for recursively defining resources
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (not supported by all writers)
    # @option options [Boolean]  :standard_prefixes   (false)
    #   Add standard prefixes to _prefixes_, if necessary.
    # @option options [String] :stylesheet (nil)
    #   URI to use as @href for output stylesheet processing instruction.
    # @option options [Array<RDF::URI>] :top_classes ([RDF::RDFS.Class])
    #   Defines rdf:type of subjects to be emitted at the beginning of the document.
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, **options, &block)
      super do
        @graph = RDF::Graph.new
        @uri_to_prefix = {}
        @uri_to_qname = {}
        @top_classes = options[:top_classes] || [RDF::RDFS.Class]

        block.call(self) if block_given?
      end
    end

    ##
    # Addes a triple to be serialized
    # @param  [RDF::Resource] subject
    # @param  [RDF::URI]      predicate
    # @param  [RDF::Value]    object
    # @return [void]
    # @raise  [NotImplementedError] unless implemented in subclass
    # @abstract
    # @raise [RDF::WriterError] if validating and attempting to write an invalid {RDF::Term}.
    def write_triple(subject, predicate, object)
      @graph.insert(RDF::Statement(subject, predicate, object))
    end

    def write_epilogue
      @max_depth = @options.fetch(:max_depth, 10)
      @attributes = @options.fetch(:attributes, :none)
      @base_uri = RDF::URI(@options[:base_uri]) if @options[:base_uri]
      @lang = @options[:lang]
      self.reset

      log_debug {"\nserialize: graph size: #{@graph.size}"}

      preprocess
      # Prefixes
      prefix = prefixes.keys.map {|pk| "#{pk}: #{prefixes[pk]}"}.sort.join(" ") unless prefixes.empty?
      log_debug {"\nserialize: prefixes: #{prefix.inspect}"}

      @subjects = order_subjects

      # Generate document
      doc = render_document(@subjects,
        lang:       @lang,
        base:       base_uri,
        prefix:     prefix,
        stylesheet: @options[:stylesheet]) do |s|
        subject(s)
      end
      @output.write(doc)

      super
    end

  protected

    # Reset parser to run again
    def reset
      @options[:log_depth] = 0
      @references = {}
      @serialized = {}
      @subjects = {}
    end

    # Render document using `haml_template[:doc]`. Yields each subject to be rendered separately.
    #
    # @param [Array<RDF::Resource>] subjects
    #   Ordered list of subjects. Template must yield to each subject, which returns
    #   the serialization of that subject (@see #subject_template)
    # @param [Hash{Symbol => Object}] options Rendering options passed to Haml render.
    # @option options [RDF::URI] base (nil)
    #   Base URI added to document, used for shortening URIs within the document.
    # @option options [Symbol, String] language (nil)
    #   Value of @lang attribute in document, also allows included literals to omit
    #   an @lang attribute if it is equivalent to that of the document.
    # @option options [String] title (nil)
    #   Value of html>head>title element.
    # @option options [String] prefix (nil)
    #   Value of @prefix attribute.
    # @option options [String] haml (haml_template[:doc])
    #   Haml template to render.
    # @yield [subject]
    #   Yields each subject
    # @yieldparam [RDF::URI] subject
    # @yieldparam [Builder::RdfXml] builder
    # @yieldreturn [:ignored]
    # @return String
    #   The rendered document is returned as a string
    def render_document(subjects, lang: nil, base: nil, **options, &block)
      builder = Builder::RdfXml.new(indent: 2)
      builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
      builder.instruct! :'xml-stylesheet', type: 'text/xsl', href: options[:stylesheet] if options[:stylesheet]
      attrs = prefix_attrs
      attrs[:"xml:lang"] = lang if lang
      attrs[:"xml:base"] = base if base

      builder.rdf(:RDF, **attrs) do |b|
        subjects.each do |subject|
          render_subject(subject, b, **options)
        end
      end
    end

    # Render a subject using `haml_template[:subject]`.
    #
    # The _subject_ template may be called either as a top-level element, or recursively under another element if the _rel_ local is not nil.
    #
    #  For RDF/XML, removes from predicates those that can be rendered as attributes, and adds the `:attr_props` local for the Haml template, which includes all attributes to be rendered as properties.
    #
    # Yields each property to be rendered separately.
    #
    # @param [Array<RDF::Resource>] subject
    #   Subject to render
    # @param [Builder::RdfXml] builder
    # @param [Hash{Symbol => Object}] options Rendering options passed to Haml render.
    # @option options [String] about (nil)
    #   About description, a QName, URI or Node definition.
    #   May be nil if no @about is rendered (e.g. unreferenced Nodes)
    # @option options [String] resource (nil)
    #   Resource description, a QName, URI or Node definition.
    #   May be nil if no @resource is rendered
    # @option options [String] rel (nil)
    #   Optional @rel property description, a QName, URI or Node definition.
    # @option options [String] typeof (nil)
    #   RDF type as a QName, URI or Node definition.
    #   If :about is nil, this defaults to the empty string ("").
    # @option options [:li, nil] element (nil)
    #   Render with &lt;li&gt;, otherwise with template default.
    # @option options [String] haml (haml_template[:subject])
    #   Haml template to render.
    # @yield [predicate]
    #   Yields each predicate
    # @yieldparam [RDF::URI] predicate
    # @yieldreturn [:ignored]
    # @return Builder::RdfXml
    def render_subject(subject, builder, **options, &block)
      return nil if is_done?(subject)

      attr_props, embed_props, types = prop_partition(properties_for_subject(subject))

      # The first type is used for
      first_type = types.shift
      type_qname = get_qname(first_type) if first_type && !first_type.node?
      type_qname = nil unless type_qname.is_a?(String)
      types.unshift(first_type) if first_type && !type_qname
      type_qname ||= "rdf:Description"

      attr_props = attr_props.merge("rdf:nodeID": subject.id) if subject.node? && ref_count(subject) >= 1
      attr_props = attr_props.merge("rdf:about": subject.relativize(base_uri)) if subject.uri?

      log_debug {"render_subject(#{subject.inspect})"}
      subject_done(subject)

      builder.tag!(type_qname, **attr_props) do |b|
        types.each do |type|
          if type.node?
            b.tag!("rdf:type",  "rdf:nodeID": type.id)
          else
            b.tag!("rdf:type",  "rdf:resource": type.to_s)
          end
        end

        log_depth do
          embed_props.each do |p, objects|
            render_property(p, objects, b, **options)
          end
        end
      end
    end

    # Render a single- or multi-valued property. Yields each object for optional rendering. The block should only render for recursive subject definitions (i.e., where the object is also a subject and is rendered underneath the first referencing subject).
    #
    # If a multi-valued property definition is not found within the template, the writer will use the single-valued property definition multiple times.
    #
    # @param [String] property
    #   Property to render, already in QName form.
    # @param [Array<RDF::Resource>] objects
    #   List of objects to render. If the list contains only a single element, the :property_value template will be used. Otherwise, the :property_values template is used.
    # @param [Builder::RdfXml] builder
    # @param [Hash{Symbol => Object}] options Rendering options passed to Haml render.
    def render_property(property, objects, builder, **options)
      log_debug {"render_property(#{property}): #{objects.inspect}"}

      # Separate out the objects which are lists and render separately
      lists = objects.
        select(&:node?).
        map {|o| RDF::List.new(subject: o, graph: @graph)}.
        select {|l| l.valid? && l.none?(&:literal?)}

      objects = objects - lists.map(&:subject)

      unless lists.empty?
        # Render non-list objects
        log_debug(depth: log_depth + 1) {"properties with lists: #{lists} non-lists: #{objects - lists.map(&:subject)}"}

        unless objects.empty?
          render_property(property,  objects, builder, **options)
        end

        # Render each list
        lists.each do |list|
          # Render each list as multiple properties and set :inlist to true
          list.each_statement {|st| subject_done(st.subject)}

          log_depth do
            log_debug {"list: #{list.inspect} #{list.to_a}"}
            render_collection(property, list, builder, **options)
          end
        end
      end

      if objects.length == 1
        recurse = log_depth <= @max_depth
        object = objects.first
        
        if recurse && !is_done?(object)
          builder.tag!(property) do |b|
            render_subject(object, b, **options)
          end
        elsif object.literal? && object.datatype == RDF.XMLLiteral
          builder.tag!(property, "rdf:parseType": "Literal", no_whitespace: true) do |b|
            b << object.value
          end
        elsif object.literal?
          attrs = {}
          attrs[:"xml:lang"] = object.language if object.language?
          attrs[:"rdf:datatype"] = object.datatype if object.datatype?
          builder.tag!(property, object.value.to_s, **attrs)
        elsif object.node?
           builder.tag!(property, "rdf:nodeID": object.id)
        else
          builder.tag!(property, "rdf:resource": object.relativize(base_uri))
        end
      else
        # Render each property using property_value template
        objects.each do |object|
          log_depth do
            render_property(property, [object], builder, **options)
          end
        end
      end
    end

    ##
    # Render a collection, which may be included in a property declaration, or
    # may be recursive within another collection
    #
    # @param [String] property in QName form
    # @param [RDF::List] list
    # @param [Builder::RdfXml] builder
    # @param [Hash{Symbol => Object}] options
    # @return String
    #   The rendered collection is returned as a string
    def render_collection(property, list, builder, **options, &block)
      builder.tag!(property, "rdf:parseType": "Collection") do |b|
        list.each do |object|
          if log_depth <= @max_depth && !is_done?(object)
            render_subject(object, b)
          elsif object.node?
            if ref_count(object) > 1
              b.tag!("rdf:Description", "rdf:nodeID": object.id)
            else
              b.tag!("rdf:Description")
            end
          else
            b.tag!("rdf:Description", "rdf:about": object.relativize(base_uri))
          end
        end
      end
    end

    # XML namespace attributes for defined prefixes
    # @return [Hash{String => String}]
    def prefix_attrs
      prefixes.inject({}) do |memo, (k, v)|
        memo[(k ? "xmlns:#{k}" : "xmlns").to_sym] = v.to_s
        memo
      end
    end

    # Perform any preprocessing of statements required
    # @return [ignored]
    def preprocess
      # Load defined prefixes
      (@options[:prefixes] || {}).each_pair do |k, v|
        @uri_to_prefix[v.to_s] = k
      end
      @options[:prefixes] = {}  # Will define actual used when matched

      prefix(:rdf, RDF.to_uri)
      @uri_to_prefix[RDF.to_uri.to_s] = :rdf
      if base_uri || @options[:lang]
        prefix(:xml, RDF::XML)
        @uri_to_prefix[RDF::XML.to_s] = :xml
      end

      if @options[:default_namespace]
        @uri_to_prefix[@options[:default_namespace]] = nil
        prefix(nil, @options[:default_namespace])
      end

      # Process each statement to establish QNames and Terms
      @graph.each {|statement| preprocess_statement(statement)}
    end

    # Perform any statement preprocessing required. This is used to perform reference counts and determine required prefixes.
    #
    # For RDF/XML, make sure that all predicates have QNames
    # @param [Statement] statement
    def preprocess_statement(statement)
      #log_debug {"preprocess: #{statement.inspect}"}
      bump_reference(statement.object)
      @subjects[statement.subject] = true
      get_qname(statement.subject)
      ensure_qname(statement.predicate)
      statement.predicate == RDF.type && statement.object.uri? ? ensure_qname(statement.object) : get_qname(statement.object)
      get_qname(statement.object.datatype) if statement.object.literal? && statement.object.datatype?
    end

  private

    # Order subjects for output. Override this to output subjects in another order.
    #
    # Uses #top_classes and #base_uri.
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      seen = {}
      subjects = []

      # Start with base_uri
      if base_uri && @subjects.keys.include?(base_uri)
        subjects << base_uri
        seen[base_uri] = true
      end

      # Add distinguished classes
      top_classes.
      select {|s| !seen.include?(s)}.
      each do |class_uri|
        graph.query({predicate: "rdf:type", object: class_uri}).map {|st| st.subject}.sort.uniq.each do |subject|
          #log_debug {"order_subjects: #{subject.inspect}"}
          subjects << subject
          seen[subject] = true
        end
      end

      # Sort subjects by resources over nodes, ref_counts and the subject URI itself
      recursable = @subjects.keys.
        select {|s| !seen.include?(s)}.
        map {|r| [r.is_a?(RDF::Node) ? 1 : 0, ref_count(r), r]}.
        sort

      log_debug {"order_subjects: #{recursable.inspect}"}

      subjects += recursable.map{|r| r.last}
    end

    # @param [RDF::Resource] subject
    # @return [Hash{String => Object}]
    def properties_for_subject(subject)
      properties = {}
      @graph.query({subject: subject}) do |st|
        key = get_qname(st.predicate.to_s)
        properties[key] ||= []
        properties[key] << st.object
      end
      properties
    end

    # Partition properties into attributed, embedded, and types
    #
    # @param [Hash{String => Array<RDF::Resource}] properties
    # @return [Hash, Hash, Array<RDF::Resource>]
    def prop_partition(properties)
      attr_props, embed_props = {}, {}

      type_prop = "rdf:type"
      types = properties.delete(type_prop)

      # extract those properties that can be rendered as attributes
      if [:untyped, :typed].include?(@attributes)
        properties.each do |prop, values|
          object = values.first
          if values.length == 1 &&
            object.literal? &&
            (object.plain? || @attributes == :typed) &&
            get_lang(object).nil?

            attr_props[prop.to_sym] = values.first.to_s
          else
            embed_props[prop] = values
          end
        end
      else
        embed_props = properties
      end

      [attr_props, embed_props, Array(types)]
    end

    # Return language for literal, if there is no language, or it is the same as the document, return nil
    #
    # @param [RDF::Literal] literal
    # @return [Symbol, nil]
    # @raise [RDF::WriterError]
    def get_lang(literal)
      if literal.is_a?(RDF::Literal)
        literal.language if literal.literal? && literal.language && literal.language.to_s != @lang.to_s
      else
        log_error("Getting language for #{literal.inspect}, which must be a literal")
        nil
      end
    end

    # Return appropriate, term, QName or URI for the given resource.
    #
    # @param [RDF::Value, String] resource
    # @return [String] value to use to identify URI
    # @raise [RDF::WriterError]
    def get_qname(resource)
      return @uri_to_qname[resource] if resource.is_a?(String) && @uri_to_qname.key?(resource)

      case resource
      when RDF::URI
        begin
          uri = resource.to_s

          qname = case
          when @uri_to_qname.key?(uri)
            @uri_to_qname[uri]
          when base_uri && uri.index(base_uri.to_s) == 0
            #log_debug {"get_qname(#{uri}): base_uri (#{uri.sub(base_uri.to_s, "")})"}
            uri.sub(base_uri.to_s, "")
          when u = @uri_to_prefix.keys.detect {|u| uri.index(u.to_s) == 0}
            #log_debug {"get_qname(#{uri}): uri_to_prefix"}
            # Use a defined prefix
            prefix = @uri_to_prefix[u]
            prefix(prefix, u)  # Define for output
            uri.sub(u.to_s, "#{prefix}:")
          when @options[:standard_prefixes] && vocab = RDF::Vocabulary.detect {|v| uri.index(v.to_uri.to_s) == 0}
            #log_debug {"get_qname(#{uri}): standard_prefixes"}
            prefix = vocab.__name__.to_s.split('::').last.downcase
            prefix(prefix, vocab.to_uri) # Define for output
            uri.sub(vocab.to_uri.to_s, "#{prefix}:")
          end

          # Don't define ill-formed qnames
          @uri_to_qname[uri] = if qname.nil? || qname == ':'
            resource
          elsif qname.start_with?(':')
            qname[1..-1]
          else
            qname
          end
        rescue ArgumentError => e
          log_error("Invalid URI #{uri.inspect}: #{e.message}")
          nil
        end
      when RDF::Node then resource.to_s
      when RDF::Literal then nil
      else
        log_error("Getting QName for #{resource.inspect}, which must be a resource")
        nil
      end
    end

    # Make sure a QName is defined
    def ensure_qname(resource)
      if get_qname(resource) == resource.to_s || get_qname(resource).split(':', 2).last =~ /[\.#]/
        uri = resource.to_s
        # No vocabulary found, invent one
        # Add bindings for predicates not already having bindings
        # From RDF/XML Syntax and Processing:
        #   An XML namespace-qualified name (QName) has restrictions on the legal characters such that not all property URIs can be expressed as these names. It is recommended that implementors of RDF serializers, in order to break a URI into a namespace name and a local name, split it after the last XML non-NCName character, ensuring that the first character of the name is a Letter or '_'. If the URI ends in a non-NCName character then throw a "this graph cannot be serialized in RDF/XML" exception or error.
        separation = uri.rindex(%r{[^a-zA-Z_0-9-][a-zA-Z_][a-z0-9A-Z_-]*$})
        return @uri_to_prefix[uri] = nil unless separation
        base_uri = uri.to_s[0..separation]
        suffix = uri.to_s[separation+1..-1]
        @gen_prefix = @gen_prefix ? @gen_prefix.succ : "ns0"
        log_debug {"ensure_qname: generated prefix #{@gen_prefix} for #{base_uri}"}
        @uri_to_prefix[base_uri] = @gen_prefix
        @uri_to_qname[uri] = "#{@gen_prefix}:#{suffix}"
        prefix(@gen_prefix, base_uri)
        get_qname(resource)
      end
    end

    # Mark a subject as done.
    # @param [RDF::Resource] subject
    # @return [Boolean]
    def subject_done(subject)
      @serialized[subject] = true
    end

    # Determine if the subject has been completed
    # @param [RDF::Resource] subject
    # @return [Boolean]
    def is_done?(subject)
      @serialized.include?(subject) || !@subjects.include?(subject)
    end

    # Increase the reference count of this resource
    # @param [RDF::Resource] resource
    # @return [Integer] resulting reference count
    def bump_reference(resource)
      @references[resource] = ref_count(resource) + 1
    end

    # Return the number of times this node has been referenced in the object position
    # @param [RDF::Node] node
    # @return [Boolean]
    def ref_count(node)
      @references.fetch(node, 0)
    end
  end
end
