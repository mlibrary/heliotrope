require 'haml'
require 'cgi'
require 'rdf/xsd'

module RDF::RDFa
  ##
  # An RDFa 1.1 serialiser in Ruby. The RDFa serializer makes use of Haml templates, allowing runtime-replacement with alternate templates. Note, however, that templates should be checked against the W3C test suite to ensure that valid RDFa is emitted.
  #
  # Note that the natural interface is to write a whole graph at a time. Writing statements or Triples will create a graph to add them to and then serialize the graph.
  #
  # The writer will add prefix definitions, and use them for creating @prefix definitions, and minting CURIEs
  #
  # @example Obtaining a RDFa writer class
  #     RDF::Writer.for(:html)          => RDF::RDFa::Writer
  #     RDF::Writer.for("etc/test.html")
  #     RDF::Writer.for(file_name:      "etc/test.html")
  #     RDF::Writer.for(file_extension: "html")
  #     RDF::Writer.for(content_type:   "application/xhtml+xml")
  #     RDF::Writer.for(content_type:   "text/html")
  #
  # @example Serializing RDF graph into an XHTML+RDFa file
  #     RDF::RDFa::Write.open("etc/test.html") do |writer|
  #       writer << graph
  #     end
  #
  # @example Serializing RDF statements into an XHTML+RDFa file
  #     RDF::RDFa::Writer.open("etc/test.html") do |writer|
  #       graph.each_statement do |statement|
  #         writer << statement
  #       end
  #     end
  #
  # @example Serializing RDF statements into an XHTML+RDFa string
  #     RDF::RDFa::Writer.buffer do |writer|
  #       graph.each_statement do |statement|
  #         writer << statement
  #       end
  #     end
  #
  # @example Creating @base and @prefix definitions in output
  #     RDF::RDFa::Writer.buffer(base_uri: "http://example.com/", prefixes: {
  #         foaf: "http://xmlns.com/foaf/0.1/"}
  #     ) do |writer|
  #       graph.each_statement do |statement|
  #         writer << statement
  #       end
  #     end
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  class Writer < RDF::Writer
    format RDF::RDFa::Format
    include RDF::Util::Logger

    # Defines rdf:type of subjects to be emitted at the beginning of the document.
    # @return [Array<URI>]
    attr :top_classes

    # Defines order of predicates to to emit at begninning of a resource description. Defaults to `[rdf:type, rdfs:label, dc:title]`
    # @return [Array<URI>]
    attr :predicate_order

    # Defines order of predicates to use in heading.
    # @return [Array<URI>]
    attr :heading_predicates

    HAML_OPTIONS = {
      format: :xhtml
    }

    # @return [Graph] Graph of statements serialized
    attr_accessor :graph

    # @return [RDF::URI] Base URI used for relativizing URIs
    attr_accessor :base_uri

    ##
    # RDFa Writer options
    # @see https://ruby-rdf.github.io/rdf/RDF/Writer#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :lang,
          datatype: String,
          on: ["--lang"],
          description: "Output as root @lang attribute, and avoid generation _@lang_ where possible."),
      ]
    end

    ##
    # Initializes the RDFa writer instance.
    #
    # @param  [IO, File] output
    #   the output stream
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize literals when serializing
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when constructing relative URIs, set as html>head>base.href
    # @option options [Boolean]  :validate (false)
    #   whether to validate terms when serializing
    # @option options [#to_s]   :lang   (nil)
    #   Output as root @lang attribute, and avoid generation _@lang_ where possible
    # @option options [Boolean]  :standard_prefixes   (false)
    #   Add standard prefixes to _prefixes_, if necessary.
    # @option options [Array<RDF::URI>] :top_classes ([RDF::RDFS.Class])
    #   Defines rdf:type of subjects to be emitted at the beginning of the document.
    # @option options [Array<RDF::URI>] :predicate_order ([RDF.type, RDF::RDFS.label, RDF::Vocab::DC.title])
    #   Defines order of predicates to to emit at begninning of a resource description..
    # @option options [Array<RDF::URI>] :heading_predicates ([RDF::RDFS.label, RDF::Vocab::DC.title])
    #   Defines order of predicates to use in heading.
    # @option options [String, Symbol, Hash{Symbol => String}] :haml (DEFAULT_HAML) HAML templates used for generating code
    # @option options [Hash] :haml_options (HAML_OPTIONS)
    #   Options to pass to Haml::Engine.new.
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, **options, &block)
      super do
        @uri_to_term_or_curie = {}
        @uri_to_prefix = {}
        @top_classes = options[:top_classes] || [RDF::RDFS.Class]
        @predicate_order = options[:predicate_order] || [RDF.type, RDF::RDFS.label, RDF::URI("http://purl.org/dc/terms/title")]
        @heading_predicates = options[:heading_predicates] || [RDF::RDFS.label, RDF::URI("http://purl.org/dc/terms/title")]
        @graph = RDF::Graph.new

        block.call(self) if block_given?
      end
    end

    # @return [Hash<Symbol => String>]
    def haml_template
      return @haml_template if @haml_template
      case @options[:haml]
      when Symbol, String   then HAML_TEMPLATES.fetch(@options[:haml].to_sym, DEFAULT_HAML)
      when Hash             then @options[:haml]
      else                       DEFAULT_HAML
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

    ##
    # Outputs the XHTML+RDFa representation of all stored triples.
    #
    # @return [void]
    def write_epilogue
      @base_uri = RDF::URI(@options[:base_uri]) if @options[:base_uri]
      @lang = @options[:lang]
      self.reset

      log_debug {"\nserialize: graph size: #{@graph.size}"}

      preprocess

      # Prefixes
      prefix = prefixes.keys.map {|pk| "#{pk}: #{prefixes[pk]}"}.sort.join(" ") unless prefixes.empty?
      log_debug {"\nserialize: prefixes: #{prefix.inspect}"}

      subjects = order_subjects

      # Take title from first subject having a heading predicate
      doc_title = nil
      titles = {}
      heading_predicates.each do |pred|
        @graph.query({predicate: pred}) do |statement|
          titles[statement.subject] ||= statement.object
        end
      end
      title_subject = subjects.detect {|subject| titles[subject]}
      doc_title = titles[title_subject]

      # Generate document
      doc = render_document(subjects,
        lang:     @lang,
        base:     base_uri,
        title:    doc_title,
        prefix:   prefix) do |s|
        subject(s)
      end
      @output.write(doc)

      super
    end

    protected

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
    # @yieldreturn [:ignored]
    # @return String
    #   The rendered document is returned as a string
    def render_document(subjects, **options)
      template = options[:haml] || :doc
      options = {
        prefix: nil,
        subjects: subjects,
        title: nil,
      }.merge(options)
      hamlify(template, **options) do |subject|
        yield(subject) if block_given?
      end.gsub(/^\s+$/m, '')
    end

    # Render a subject using `haml_template[:subject]`.
    #
    # The _subject_ template may be called either as a top-level element, or recursively under another element if the _rel_ local is not nil.
    #
    # Yields each predicate/property to be rendered separately (@see #render_property_value and `#render_property_values`).
    #
    # @param [Array<RDF::Resource>] subject
    #   Subject to render
    # @param [Array<RDF::Resource>] predicates
    #   Predicates of subject. Each property is yielded for separate rendering.
    # @param [Hash{Symbol => Object}] options Rendering options passed to Haml render.
    # @option options [String] about (nil)
    #   About description, a CURIE, URI or Node definition.
    #   May be nil if no @about is rendered (e.g. unreferenced Nodes)
    # @option options [String] resource (nil)
    #   Resource description, a CURIE, URI or Node definition.
    #   May be nil if no @resource is rendered
    # @option options [String] rel (nil)
    #   Optional @rel property description, a CURIE, URI or Node definition.
    # @option options [String] typeof (nil)
    #   RDF type as a CURIE, URI or Node definition.
    #   If :about is nil, this defaults to the empty string ("").
    # @option options [:li, nil] element (nil)
    #   Render with &lt;li&gt;, otherwise with template default.
    # @option options [String] haml (haml_template[:subject])
    #   Haml template to render.
    # @yield [predicate]
    #   Yields each predicate
    # @yieldparam [RDF::URI] predicate
    # @yieldreturn [:ignored]
    # @return String
    #   The rendered document is returned as a string
    # Return Haml template for document from `haml_template[:subject]`
    def render_subject(subject, predicates, **options)
      template = options[:haml] || :subject
      options = {
        about:      (get_curie(subject) unless options[:rel]),
        base:       base_uri,
        element:    nil,
        predicates: predicates,
        rel:        nil,
        inlist:     nil,
        resource:   (get_curie(subject) if options[:rel]),
        subject:    subject,
        typeof:     nil,
      }.merge(options)
      hamlify(template, **options) do |predicate|
        yield(predicate) if block_given?
      end
    end

    # Render a single- or multi-valued predicate using `haml_template[:property_value]` or `haml_template[:property_values]`. Yields each object for optional rendering. The block should only render for recursive subject definitions (i.e., where the object is also a subject and is rendered underneath the first referencing subject).
    #
    # If a multi-valued property definition is not found within the template, the writer will use the single-valued property definition multiple times.
    #
    # @param [Array<RDF::Resource>] predicate
    #   Predicate to render.
    # @param [Array<RDF::Resource>] objects
    #   List of objects to render. If the list contains only a single element, the :property_value template will be used. Otherwise, the :property_values template is used.
    # @param [Hash{Symbol => Object}] options Rendering options passed to Haml render.
    # @option options [String] :haml (haml_template[:property_value], haml_template[:property_values])
    #   Haml template to render. Otherwise, uses `haml_template[:property_value] or haml_template[:property_values]`
    #   depending on the cardinality of objects.
    # @yield object, inlist
    #   Yields object and if it is contained in a list.
    # @yieldparam [RDF::Resource] object
    # @yieldparam [Boolean] inlist
    # @yieldreturn [String, nil]
    #   The block should only return a string for recursive object definitions.
    # @return String
    #   The rendered document is returned as a string
    def render_property(predicate, objects, **options, &block)
      log_debug {"render_property(#{predicate}): #{objects.inspect}, #{options.inspect}"}
      # If there are multiple objects, and no :property_values is defined, call recursively with
      # each object

      template = options[:haml]
      template ||= objects.length > 1 ? haml_template[:property_values] : haml_template[:property_value]

      # Separate out the objects which are lists and render separately
      list_objects = objects.reject do |o|
        o == RDF.nil ||
        (l = RDF::List.new(subject: o, graph: @graph)).invalid?
      end
      unless list_objects.empty?
        # Render non-list objects
        log_debug {"properties with lists: #{list_objects} non-lists: #{objects - list_objects}"}
        nl = log_depth {render_property(predicate, objects - list_objects, **options, &block)} unless objects == list_objects
        return nl.to_s + list_objects.map do |object|
          # Render each list as multiple properties and set :inlist to true
          list = RDF::List.new(subject: object, graph: @graph)
          list.each_statement {|st| subject_done(st.subject)}

          log_debug {"list: #{list.inspect} #{list.to_a}"}
          log_depth do
            render_property(predicate, list.to_a, **options.merge(inlist: "true")) do |object|
              yield(object, true) if block_given?
            end
          end
        end.join(" ")
      end

      if objects.length > 1 && template.nil?
        # If there is no property_values template, render each property using property_value template
        objects.map do |object|
          log_depth {render_property(predicate, [object], **options, &block)}
        end.join(" ")
      else
        log_fatal("Missing property template", exception: RDF::WriterError) if template.nil?

        template = options[:haml] || (
          objects.to_a.length > 1 &&
          haml_template.has_key?(:property_values) ?
            :property_values :
            :property_value)
        options = {
          objects:    objects,
          object:     objects.first,
          predicate:  predicate,
          property:   get_curie(predicate),
          rel:        get_curie(predicate),
          inlist:     nil,
        }.merge(options)
        hamlify(template, options, &block)
      end
    end

    # Perform any preprocessing of statements required
    # @return [ignored]
    def preprocess
      # Load initial contexts
      # Add terms and prefixes to local store for converting URIs
      # Keep track of vocabulary from left-most context
      [XML_RDFA_CONTEXT, HTML_RDFA_CONTEXT].each do |uri|
        ctx = Context.find(uri)
        ctx.prefixes.each_pair do |k, v|
          @uri_to_prefix[v] = k unless k.to_s == "dcterms"
        end

        ctx.terms.each_pair do |k, v|
          @uri_to_term_or_curie[v] = k.to_s
        end

        @vocabulary = ctx.vocabulary.to_s if ctx.vocabulary
      end

      # Load defined prefixes
      (@options[:prefixes] || {}).each_pair do |k, v|
        @uri_to_prefix[v.to_s] = k
      end
      @options[:prefixes] = {}  # Will define actual used when matched

      # Process each statement to establish CURIEs and Terms
      @graph.each {|statement| preprocess_statement(statement)}
    end

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
        graph.query({predicate: RDF.type, object: class_uri}).map {|st| st.subject}.sort.uniq.each do |subject|
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

    # Take a hash from predicate uris to lists of values.
    # Sort the lists of values.  Return a sorted list of properties.
    #
    # @param [Hash{String => Array<Resource>}] properties A hash of Property to Resource mappings
    # @return [Array<String>}] Ordered list of properties. Uses predicate_order.
    def order_properties(properties)
      # Make sorted list of properties
      prop_list = []

      predicate_order.each do |prop|
        next unless properties[prop.to_s]
        prop_list << prop.to_s
      end

      properties.keys.sort.each do |prop|
        next if prop_list.include?(prop.to_s)
        prop_list << prop.to_s
      end

      log_debug {"order_properties: #{prop_list.join(', ')}"}
      prop_list
    end

    # Perform any statement preprocessing required. This is used to perform reference counts and determine required prefixes.
    # @param [RDF::Statement] statement
    # @return [ignored]
    def preprocess_statement(statement)
      #log_debug {"preprocess: #{statement.inspect}"}
      bump_reference(statement.object)
      @subjects[statement.subject] = true
      get_curie(statement.subject)
      get_curie(statement.predicate)
      get_curie(statement.object)
      get_curie(statement.object.datatype) if statement.object.literal? && statement.object.has_datatype?
    end

    # Reset parser to run again
    def reset
      @options[:log_depth] = 0
      prefixes = {}
      @references = {}
      @serialized = {}
      @subjects = {}
    end

    protected

    # Display a subject.
    #
    # If the Haml template contains an entry matching the subject's rdf:type URI, that entry will be used as the template for this subject and it's properties.
    #
    # @example Displays a subject as a Resource Definition:
    #     <div typeof="rdfs:Resource" about="http://example.com/resource">
    #       <h1 property="dc:title">label</h1>
    #       <ul>
    #         <li content="2009-04-30T06:15:51Z" property="dc:created">2009-04-30T06:15:51+00:00</li>
    #       </ul>
    #     </div>
    #
    # @param [RDF::Resource] subject
    # @param [Hash{Symbol => Object}] options
    # @option options [:li, nil] :element(:div)
    #   Serialize using &lt;li&gt; rather than template default element
    # @option options [RDF::Resource] :rel (nil)
    #   Optional @rel property
    # @return [String]
    def subject(subject, **options)
      return if is_done?(subject)

      subject_done(subject)

      properties = properties_for_subject(subject)
      typeof = type_of(properties.delete(RDF.type.to_s), subject)
      prop_list = order_properties(properties)

      log_debug {"props: #{prop_list.inspect}"}

      render_opts = {typeof: typeof, property_values: properties}.merge(options)

      render_subject_template(subject, prop_list, **render_opts)
    end

    # @param [RDF::Resource] subject
    # @return [Hash{String => Object}]
    def properties_for_subject(subject)
      properties = {}
      @graph.query({subject: subject}) do |st|
        key = st.predicate.to_s.freeze
        properties[key] ||= []
        properties[key] << st.object
      end
      properties
    end

    # @param [Array,NilClass] type
    # @param [RDF::Resource] subject
    # @return [String] string representation of the specific RDF.type uri
    def type_of(type, subject)
      # Find appropriate template
      curie = case
      when subject.node?
        subject.to_s if ref_count(subject) > 1
      else
        get_curie(subject)
      end

      typeof = Array(type).map {|r| get_curie(r)}.join(" ")
      typeof = nil if typeof.empty?

      # Nodes without a curie need a blank @typeof to generate a subject
      typeof ||= "" unless curie

      log_debug {"subject: #{curie.inspect}, typeof: #{typeof.inspect}" }

      typeof.freeze
    end

    # @param [RDF::Resource] subject
    # @param [Array] prop_list
    # @param [Hash] render_opts
    # @return [String]
    def render_subject_template(subject, prop_list, **render_opts)
      # See if there's a template based on the sorted concatenation of all types of this subject
      # or any type of this subject
      tmpl = find_template(subject)
      log_debug {"subject: found template #{tmpl[:identifier] || tmpl.inspect}"} if tmpl

      # Render this subject
      # If :rel is specified and :typeof is nil, use @resource instead of @about.
      # Pass other options from calling context
      with_template(tmpl) do
        render_subject(subject, prop_list, **render_opts) do |pred|
          log_depth do
            pred = RDF::URI(pred) if pred.is_a?(String)
            values = render_opts[:property_values][pred.to_s]
            log_debug {"subject: #{get_curie(subject)}, pred: #{get_curie(pred)}, values: #{values.inspect}"}
            predicate(pred, values)
          end
        end
      end
    end

    # Write a predicate with one or more values.
    #
    # Values may be a combination of Literal and Resource (Node or URI).
    # @param [RDF::Resource] predicate
    #   Predicate to serialize
    # @param [Array<RDF::Resource>] objects
    #   Objects to serialize
    # @return [String]
    def predicate(predicate, objects)
      log_debug {"predicate: #{predicate.inspect}, objects: #{objects}"}

      return if objects.to_a.empty?

      log_debug {"predicate: #{get_curie(predicate)}"}
      render_property(predicate, objects) do |o, inlist=nil|
        # Yields each object, for potential recursive definition.
        # If nil is returned, a leaf is produced
        log_depth {subject(o, rel: get_curie(predicate), inlist: inlist, element: (:li if objects.length > 1 || inlist))} if !is_done?(o) && @subjects.include?(o)
      end
    end

    # Haml rendering helper. Return CURIE for the literal datatype, if the literal is a typed literal.
    #
    # @param [RDF::Resource] literal
    # @return [String, nil]
    # @raise [RDF::WriterError]
    def get_dt_curie(literal)
      if literal.is_a?(RDF::Literal)
        get_curie(literal.datatype) if literal.literal? && literal.datatype?
      else
        log_error("Getting datatype CURIE for #{literal.inspect}, which must be a literal")
        nil
      end
    end

    # Haml rendering helper. Return language for plain literal, if there is no language, or it is the same as the document, return nil
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

    # Haml rendering helper. Data to be added to a @content value, for specific datatypes
    #
    # @param [RDF::Literal] literal
    # @return [String, nil]
    # @raise [RDF::WriterError]
    def get_content(literal)
      case literal
      when RDF::Literal::Date, RDF::Literal::Time, RDF::Literal::DateTime, RDF::Literal::Duration
        literal.to_s
      when RDF::Literal then nil
      else
        log_error("Getting content for #{literal.inspect}, which must be a literal")
        nil
      end
    end

    # Haml rendering helper. Display value for object, may be humanized into a non-canonical form
    #
    # @param [RDF::Literal] literal
    # @return [String]
    # @raise [RDF::WriterError]
    def get_value(literal)
      if literal.is_a?(RDF::Literal)
        literal.humanize
      else
        log_error("Getting value for #{literal.inspect}, which must be a literal")
        nil
      end
    end

    # Haml rendering helper. Return an appropriate label for a resource.
    #
    # @param [RDF::Resource] resource
    # @return [String]
    # @raise [RDF::WriterError]
    def get_predicate_name(resource)
      if resource.is_a?(RDF::URI)
        get_curie(resource)
      else
        log_error("Getting predicate name for #{resource.inspect}, which must be a URI")
        nil
      end
    end

    # Haml rendering helper. Return appropriate, term, CURIE or URI for the given resource.
    #
    # @param [RDF::Value] resource
    # @return [String] value to use to identify URI
    # @raise [RDF::WriterError]
    def get_curie(resource)
      case resource
      when RDF::URI
        begin
          uri = resource.to_s

          curie = case
          when @uri_to_term_or_curie.has_key?(uri)
            log_debug {"get_curie(#{uri}): uri_to_term_or_curie #{@uri_to_term_or_curie[uri].inspect}"}
            return @uri_to_term_or_curie[uri]
          when base_uri && uri.index(base_uri.to_s) == 0
            log_debug {"get_curie(#{uri}): base_uri (#{uri.sub(base_uri.to_s, "")})"}
            uri.sub(base_uri.to_s, "")
          when @vocabulary && uri.index(@vocabulary) == 0
            log_debug {"get_curie(#{uri}): vocabulary"}
            uri.sub(@vocabulary, "")
          when u = @uri_to_prefix.keys.detect {|u| uri.index(u.to_s) == 0}
            log_debug {"get_curie(#{uri}): uri_to_prefix"}
            # Use a defined prefix
            prefix = @uri_to_prefix[u]
            prefix(prefix, u)  # Define for output
            uri.sub(u.to_s, "#{prefix}:")
          when @options[:standard_prefixes] && vocab = RDF::Vocabulary.detect {|v| uri.index(v.to_uri.to_s) == 0}
            log_debug {"get_curie(#{uri}): standard_prefixes"}
            prefix = vocab.__name__.to_s.split('::').last.downcase
            prefix(prefix, vocab.to_uri) # Define for output
            uri.sub(vocab.to_uri.to_s, "#{prefix}:")
          else
            log_debug {"get_curie(#{uri}): none"}
            uri
          end

          #log_debug {"get_curie(#{resource}) => #{curie}"}

          @uri_to_term_or_curie[uri] = curie
        rescue ArgumentError => e
          log_error("Invalid URI #{uri.inspect}: #{e.message}")
          nil
        end
      when RDF::Node then resource.to_s
      when RDF::Literal then nil
      else
        log_error("Getting CURIE for #{resource.inspect}, which must be a resource")
        nil
      end
    end
    private

    ##
    # Haml rendering helper. Escape entities to avoid whitespace issues.
    #
    # # In addtion to "&<>, encode \n and \r to ensure that whitespace is properly preserved
    #
    # @param [String] str
    # @return [String]
    #   Entity-encoded string
    def escape_entities(str)
      # Haml 6 does escaping
      return str if Haml.const_defined?(:Template)
      CGI.escapeHTML(str).gsub(/[\n\r]/) {|c| '&#x' + c.unpack('h').first + ';'}
    end

    # Set the template to use within block
    # @param [Hash{Symbol => String}] templ template to use for block evaluation; merged in with the existing template.
    # @yield
    #   Yields with no arguments
    # @yieldreturn [Object] returns the result of yielding
    # @return [Object]
    def with_template(templ)
      if templ
        new_template = @options[:haml].
          reject {|k,v| ![:subject, :property_value, :property_values, :rel].include?(k)}.
          merge(templ || {})
        old_template, @haml_template = @haml_template, new_template
      else
        old_template = @haml_template
      end

      res = yield
      # Restore template
      @haml_template = old_template

      res
    end

    # Render HAML
    # @param [Symbol, String] template
    #   If a symbol, finds a matching template from haml_template, otherwise uses template as is
    # @param [Hash{Symbol => Object}] locals
    #   Locals to pass to render
    # @return [String]
    # @raise [RDF::WriterError]
    def hamlify(template, locals = {})
      log_debug {"hamlify template: #{template}"}
      template = haml_template[template] if template.is_a?(Symbol)

      template = template.align_left
      log_debug {"hamlify locals: #{locals.inspect}"}

      haml_opts = @options[:haml_options] || HAML_OPTIONS
      haml_runner = if Haml::VERSION >= "6"
        Haml::Template.new(**haml_opts) {template}
      else
        Haml::Engine.new(template, **haml_opts)
      end
      haml_runner.render(self, locals) do |*args|
        yield(*args) if block_given?
      end
    rescue Haml::Error => e
      log_fatal("#{e.inspect}\n" +
        "rendering #{template}\n" +
        "with options #{(@options[:haml_options] || HAML_OPTIONS).inspect}\n" +
        "and locals #{locals.inspect}",
        exception: RDF::WriterError
      )
    end

    ##
    # Find a template appropriate for the subject.
    # Override this method to provide templates based on attributes of a given subject
    #
    # @param [RDF::URI] subject
    # @return [Hash] # return matched matched template
    def find_template(subject); end

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
      @serialized.include?(subject)
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

require 'rdf/rdfa/writer/haml_templates'
