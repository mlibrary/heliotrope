begin
  require 'nokogiri'
rescue LoadError
  :rexml
end
require 'rdf/ntriples'
require 'rdf/xsd'

module RDF::RDFa
  ##
  # An RDFa parser in Ruby
  #
  # This class supports [Nokogiri][] for HTML
  # processing, and will automatically select the most performant
  # implementation (Nokogiri or LibXML) that is available. If need be, you
  # can explicitly override the used implementation by passing in a
  # `:library` option to `Reader.new` or `Reader.open`.
  #
  # [Nokogiri]: https://nokogiri.org/
  #
  # Based on processing rules described here:
  # @see https://www.w3.org/TR/rdfa-syntax/#s_model RDFa 1.0
  # @see https://www.w3.org/TR/2012/REC-rdfa-core-20120607/
  # @see https://www.w3.org/TR/2012/CR-xhtml-rdfa-20120313/
  # @see https://dev.w3.org/html5/rdfa/
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  class Reader < RDF::Reader
    format Format
    include Expansion
    include RDF::Util::Logger

    XHTML = "http://www.w3.org/1999/xhtml"

    # Content model for @about and @resource. In RDFa 1.0, this was URIorSafeCURIE
    SafeCURIEorCURIEorIRI = {
      :"rdfa1.0" => [:safe_curie, :uri, :bnode],
      :"rdfa1.1" => [:safe_curie, :curie, :uri, :bnode],
    }

    # Content model for @datatype. In RDFa 1.0, this was CURIE
    # Also plural TERMorCURIEorAbsIRIs, content model for @rel, @rev, @property and @typeof
    TERMorCURIEorAbsIRI = {
      :"rdfa1.0" => [:term, :curie],
      :"rdfa1.1" => [:term, :curie, :absuri],
    }

    # This expression matches an NCName as defined in
    # [XML-NAMES](https://www.w3.org/TR/2009/REC-xml-names-20091208/#NT-NCName)
    #
    # @see https://www.w3.org/TR/2009/REC-xml-names-20091208/#NT-NCName
    NC_REGEXP = Regexp.new(
      %{^
        (  [a-zA-Z_]
         | \\\\u[0-9a-fA-F]{4}
        )
        (  [0-9a-zA-Z_\.-/]
         | \\\\u([0-9a-fA-F]{4})
        )*
      $},
      Regexp::EXTENDED)

    # This expression matches an term as defined in
    # [RDFA-CORE](https://www.w3.org/TR/2012/REC-rdfa-core-20120607/#s_terms)
    #
    # For the avoidance of doubt, this definition means a 'term'
    # in RDFa is an XML NCName that also permits slash as a non-leading character.
    # @see https://www.w3.org/TR/2012/REC-rdfa-core-20120607/#s_terms
    TERM_REGEXP = Regexp.new(
      %{^
        (?!\\\\u0301)             # &#x301; is a non-spacing acute accent.
                                  # It is legal within an XML Name, but not as the first character.
        (  [a-zA-Z_]
         | \\\\u[0-9a-fA-F]{4}
        )
        (  [-0-9a-zA-Z_\.\/]
         | \\\\u([0-9a-fA-F]{4})
        )*
      $},
      Regexp::EXTENDED)

    # Host language
    # @!attribute [r] host_language
    # @return [:xml, :xhtml1, :xhtml5, :html4, :html5, :svg]
    attr_reader :host_language

    # Version
    # @!attribute [r] version
    # @return [:"rdfa1.0", :"rdfa1.1"]
    attr_reader :version

    # Repository used for collecting triples.
    # @!attribute [r] repository
    # @return [RDF::Repository]
    attr_reader :repository

    # Returns the XML implementation module for this reader instance.
    #
    # @!attribute [rw] implementation
    # @return [Module]
    attr_reader :implementation

    # The Recursive Baggage
    # @private
    class EvaluationContext # :nodoc:
      ##
      # The base.
      #
      # This will usually be the URL of the document being processed,
      # but it could be some other URL, set by some other mechanism,
      # such as the (X)HTML base element. The important thing is that it establishes
      # a URL against which relative paths can be resolved.
      #
      # @!attribute [rw] base
      # @return [RDF::URI]
      attr_accessor :base

      ##
      # The parent subject.
      #
      # The initial value will be the same as the initial value of base,
      # but it will usually change during the course of processing.
      #
      # @!attribute [rw] parent_subject
      # @return [RDF::URI]
      attr_accessor :parent_subject

      ##
      # The parent object.
      #
      # In some situations the object of a statement becomes the subject of any nested statements,
      # and this property is used to convey this value.
      # Note that this value may be a bnode, since in some situations a number of nested statements
      # are grouped together on one bnode.
      # This means that the bnode must be set in the containing statement and passed down,
      # and this property is used to convey this value.
      #
      # @!attribute [rw] parent_object
      # @return [RDF::URI]
      attr_accessor :parent_object

      ##
      # A list of current, in-scope URI mappings.
      #
      # @!attribute [rw] uri_mappings
      # @return [Hash{Symbol => String}]
      attr_accessor :uri_mappings

      ##
      # A list of current, in-scope Namespaces. This is the subset of uri_mappings
      # which are defined using xmlns.
      #
      # @!attribute [rw] namespaces
      # @return [Hash{String => Namespace}]
      attr_accessor :namespaces

      ##
      # A list of incomplete triples.
      #
      # A triple can be incomplete when no object resource
      # is provided alongside a predicate that requires a resource (i.e., @rel or @rev).
      # The triples can be completed when a resource becomes available,
      # which will be when the next subject is specified (part of the process called chaining).
      #
      # @!attribute [rw] incomplete_triples
      # @return [Array<Array<RDF::URI, RDF::Resource>>]
      attr_accessor :incomplete_triples

      ##
      # The language. Note that there is no default language.
      #
      # @!attribute [rw] language
      # @return [Symbol]
      attr_accessor :language

      ##
      # The term mappings, a list of terms and their associated URIs.
      #
      # This specification does not define an initial list.
      # Host Languages may define an initial list.
      # If a Host Language provides an initial list, it should do so via an RDFa Context document.
      #
      # @!attribute [rw] term_mappings
      # @return [Hash{Symbol => RDF::URI}]
      attr_accessor :term_mappings

      ##
      # The default vocabulary
      #
      # A value to use as the prefix URI when a term is used.
      # This specification does not define an initial setting for the default vocabulary.
      # Host Languages may define an initial setting.
      #
      # @!attribute [rw] default_vocabulary
      # @return [RDF::URI]
      attr_accessor :default_vocabulary

      ##
      # lists
      #
      # A hash associating lists with properties.
      # @!attribute [rw] list_mapping
      # @return [Hash{RDF:URI: Array<RDF::Resource>}]
      attr_accessor :list_mapping

      # @param [RDF::URI] base
      # @param [Hash] host_defaults
      # @option host_defaults [Hash{String => RDF::URI}] :term_mappings Hash of NCName => URI
      # @option host_defaults [Hash{String => RDF::URI}] :vocabulary Hash of prefix => URI
      def initialize(base, host_defaults)
        # Initialize the evaluation context, [5.1]
        @base = base
        @parent_subject = @base
        @parent_object = nil
        @namespaces = {}
        @incomplete_triples = []
        @language = nil
        @uri_mappings = host_defaults.fetch(:uri_mappings, {})
        @term_mappings = host_defaults.fetch(:term_mappings, {})
        @default_vocabulary = host_defaults.fetch(:vocabulary, nil)
      end

      # Copy this Evaluation Context
      #
      # @param [EvaluationContext] from
      def initialize_copy(from)
        # clone the evaluation context correctly
        @uri_mappings = from.uri_mappings.clone
        @incomplete_triples = from.incomplete_triples.clone
        @namespaces = from.namespaces.clone
        @list_mapping = from.list_mapping # Don't clone
      end

      def inspect
        v = ['base', 'parent_subject', 'parent_object', 'language', 'default_vocabulary'].map do |a|
          "#{a}=#{o = self.send(a); o.respond_to?(:to_ntriples) ? o.to_ntriples : o.inspect}"
        end
        v << "uri_mappings[#{uri_mappings.keys.length}]"
        v << "incomplete_triples[#{incomplete_triples.length}]"
        v << "term_mappings[#{term_mappings.keys.length}]"
        v << "lists[#{list_mapping.keys.length}]" if list_mapping
        v.join(", ")
      end
    end

    ##
    # RDFa Reader options
    # @see https://ruby-rdf.github.io/rdf/RDF/Reader#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :vocab_expansion,
          datatype: TrueClass,
          on: ["--vocab-expansion"],
          description: "Perform OWL2 expansion on the resulting graph.") {true},
        RDF::CLI::Option.new(
          symbol: :host_language,
          datatype: %w(xml xhtml1 xhtml5 html4 svg),
          on: ["--host-language HOSTLANG", %w(xml xhtml1 xhtml5 html4 svg)],
          description: "Host Language. One of xml, xhtml1, xhtml5, html4, or svg") do |arg|
            arg.to_sym
        end,
        RDF::CLI::Option.new(
          symbol: :rdfagraph,
          datatype: %w(output processor both),
          on: ["--rdfagraph RDFAGRAPH", %w(output processor both)],
          description: "Used to indicate if either or both of the :output or :processor graphs are output.") {|arg| arg.to_sym},
      ]
    end

    ##
    # Initializes the RDFa reader instance.
    #
    # @param  [IO, File, String] input
    #   the input stream to read
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Reader#initialize`)
    # @option options [Symbol] :library
    #   One of :nokogiri or :rexml. If nil/unspecified uses :nokogiri if available, :rexml otherwise.
    # @option options [Boolean]  :vocab_expansion (false)
    #   whether to perform OWL2 expansion on the resulting graph
    # @option options [Boolean]  :reference_folding (true)
    #   whether to perform RDFa property copying on the resulting graph
    # @option options [:xml, :xhtml1, :xhtml5, :html4, :html5, :svg] :host_language (:html5)
    #   Host Language
    # @option options [:"rdfa1.0", :"rdfa1.1"] :version (:"rdfa1.1")
    #   Parser version information
    # @option options [Proc]    :processor_callback (nil)
    #   Callback used to provide processor graph triples.
    # @option options [Array<Symbol>]    :rdfagraph ([:output])
    #   Used to indicate if either or both of the :output or :processor graphs are output.
    #   Value is an array containing on or both of :output or :processor.
    # @option options [Repository] :vocab_repository (nil)
    #   Repository to save loaded vocabularies.
    # @return [reader]
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [RDF::ReaderError] if _validate_
    def initialize(input = $stdin, **options, &block)
      super do
        @options = {reference_folding: true}.merge(@options)
        @repository = RDF::Repository.new

        @options[:rdfagraph] = case @options[:rdfagraph]
        when 'all' then [:output, :processor]
        when String, Symbol then @options[:rdfagraph].to_s.split(',').map(&:strip).map(&:to_sym)
        when Array then @options[:rdfagraph].map {|o| o.to_s.to_sym}
        else  []
        end.select {|o| [:output, :processor].include?(o)}
        @options[:rdfagraph] << :output if @options[:rdfagraph].empty?

        @library = case options[:library]
          when nil
            # Use Nokogiri when available, and REXML otherwise:
            defined?(::Nokogiri) ? :nokogiri : :rexml
          when :nokogiri, :rexml
            options[:library]
          else
            raise ArgumentError.new("expected :rexml or :nokogiri, but got #{options[:library].inspect}")
        end

        require "rdf/rdfa/reader/#{@library}"
        @implementation = case @library
          when :nokogiri then Nokogiri
          when :rexml    then REXML
        end
        self.extend(@implementation)

        detect_host_language_version(input, **options)

        add_info(@doc, "version = #{@version},  host_language = #{@host_language}, library = #{@library}, rdfagraph = #{@options[:rdfagraph].inspect}, expand = #{@options[:vocab_expansion]}")

        begin
          initialize_xml(input, **options)
        rescue
          add_error(nil, "Malformed document: #{$!.message}")
        end
        add_error(nil, "Empty document") if root.nil?
        add_error(nil, doc_errors.map(&:message).uniq.join("\n")) if !doc_errors.empty?

        # Section 4.2 RDFa Host Language Conformance
        #
        # The Host Language may require the automatic inclusion of one or more Initial Contexts
        @host_defaults = {
          vocabulary:       nil,
          uri_mappings:     {},
          initial_contexts: [],
        }

        if @version == :"rdfa1.0"
          # Add default term mappings
          @host_defaults[:term_mappings] = %w(
            alternate appendix bookmark cite chapter contents copyright first glossary help icon index
            last license meta next p3pv1 prev role section stylesheet subsection start top up
            ).inject({}) { |hash, term| hash[term] = RDF::URI("http://www.w3.org/1999/xhtml/vocab#") + term; hash }
        end

        case @host_language
        when :xml, :svg
          @host_defaults[:initial_contexts] = [XML_RDFA_CONTEXT]
        when :xhtml1
          @host_defaults[:initial_contexts] = [XML_RDFA_CONTEXT, XHTML_RDFA_CONTEXT]
        when :xhtml5, :html4, :html5
          @host_defaults[:initial_contexts] = [XML_RDFA_CONTEXT, HTML_RDFA_CONTEXT]
        end

        block.call(self) if block_given?
      end
    end

    ##
    # Extracts RDF from script element, or embeded RDF/XML
    def extract_script(el, input, type, **options, &block)
      add_debug(el, "script element of type #{type}")
      begin
        # Formats don't exist unless they've been required
        case type.to_s
        when 'application/csvm+json' then require 'rdf/tabular'
        when 'application/ld+json'   then require 'json/ld'
        when 'application/rdf+xml'   then require 'rdf/rdfxml'
        when 'text/ntriples'         then require 'rdf/ntriples'
        when 'text/turtle'           then require 'rdf/turtle'
        end
      rescue LoadError
      end

      @readers ||= {}
      reader = @readers[type.to_s] = RDF::Reader.for(content_type: type.to_s) unless @readers.has_key?(type.to_s)
      if reader = @readers[type.to_s]
        add_debug(el, "=> reader #{reader.to_sym}")
        # Wrap input in a RemoteDocument with appropriate content-type and base
        doc = if input.is_a?(String)
          RDF::Util::File::RemoteDocument.new(input, content_type: type.to_s, **options)
        else
          input
        end
        reader.new(doc, **options).each(&block)
      else
        add_debug(el, "=> no reader found")
      end
    end

    ##
    # Iterates the given block for each RDF statement in the input.
    #
    # Reads to graph and performs expansion if required.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        unless @processed || @root.nil?
          # Add prefix definitions from host defaults
          @host_defaults[:uri_mappings].each_pair do |prefix, value|
            prefix(prefix, value)
          end

          # parse
          parse_whole_document(@doc, RDF::URI(base_uri))

          # Look for Embedded RDF/XML
          unless @root.xpath("//rdf:RDF", "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#").empty?
            extract_script(@root, @doc, "application/rdf+xml", **@options.merge(base_uri: base_uri)) do |statement|
              @repository << statement
            end
          end

          # Look for Embedded microdata
          unless @root.xpath("//@itemscope").empty?
            begin
              require 'rdf/microdata'
              add_debug(@doc, "process microdata")
              @repository << RDF::Microdata::Reader.new(@doc, **options)
            rescue LoadError
              add_debug(@doc, "microdata detected, not processed")
            end
          end

          # Perform property copying
          copy_properties(@repository) if @options[:reference_folding]

          # Perform vocabulary expansion
          expand(@repository) if @options[:vocab_expansion]

          @processed = true
        end

        # Return statements in the default graph for
        # statements in the associated named or default graph from the
        # processed repository
        @repository.each do |statement|
          case statement.graph_name
          when nil
            yield statement if @options[:rdfagraph].include?(:output)
          when RDF::RDFA.ProcessorGraph
            yield RDF::Statement.new(*statement.to_triple) if @options[:rdfagraph].include?(:processor)
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

    # Figure out the document path, if it is an Element or Attribute
    def node_path(node)
      "<#{base_uri}>#{node.respond_to?(:display_path) ? node.display_path : node}"
    end

    # Add debug event to debug array, if specified
    #
    # @param [#display_path, #to_s] node XML Node or string for showing context
    # @param [String] message
    # @yieldreturn [String] appended to message, to allow for lazy-evaulation of message
    def add_debug(node, message = "", &block)
      add_processor_message(node, message, nil, &block)
    end

    def add_info(node, message, process_class = RDF::RDFA.Info, &block)
      add_processor_message(node, message, process_class, &block)
    end

    def add_warning(node, message, process_class = RDF::RDFA.Warning)
      add_processor_message(node, message, process_class)
    end

    def add_error(node, message, process_class = RDF::RDFA.Error)
      add_processor_message(node, message, process_class)
    end

    def add_processor_message(node, message, process_class, &block)
      case process_class
      when RDF::RDFA.Error    then log_error(node_path(node), message, &block)
      when RDF::RDFA.Warning  then log_warn(node_path(node), message, &block)
      when RDF::RDFA.Info     then log_info(node_path(node), message, &block)
      else                         log_debug(node_path(node), message, &block)
      end
      process_class ||= RDF::RDFA.Info
      if @options[:processor_callback] || @options[:rdfagraph].include?(:processor)
        n = RDF::Node.new
        processor_statements = [
          RDF::Statement.new(n, RDF["type"], process_class, graph_name: RDF::RDFA.ProcessorGraph),
          RDF::Statement.new(n, RDF::URI("http://purl.org/dc/terms/description"), message, graph_name: RDF::RDFA.ProcessorGraph),
          RDF::Statement.new(n, RDF::URI("http://purl.org/dc/terms/date"), RDF::Literal::Date.new(DateTime.now), graph_name: RDF::RDFA.ProcessorGraph)
        ]
        processor_statements << RDF::Statement.new(n, RDF::RDFA.context, base_uri, graph_name: RDF::RDFA.ProcessorGraph) if base_uri
        if node.respond_to?(:path)
          nc = RDF::Node.new
          processor_statements += [
            RDF::Statement.new(n, RDF::RDFA.context, nc, graph_name: RDF::RDFA.ProcessorGraph),
            RDF::Statement.new(nc, RDF["type"], RDF::PTR.XPathPointer, graph_name: RDF::RDFA.ProcessorGraph),
            RDF::Statement.new(nc, RDF::PTR.expression, node.path, graph_name: RDF::RDFA.ProcessorGraph)
          ]
        end

        @repository.insert(*processor_statements)
        if cb = @options[:processor_callback]
          processor_statements.each {|s| cb.call(s)}
        end
      end
    end

    ##
    # add a statement, object can be literal or URI or bnode
    # Yields {RDF::Statement} to the saved callback
    #
    # @param [#display_path, #to_s] node XML Node or string for showing context
    # @param [RDF::Resource] subject the subject of the statement
    # @param [RDF::URI] predicate the predicate of the statement
    # @param [RDF::Value] object the object of the statement
    # @param [RDF::Value] graph_name the graph name of the statement
    # @raise [RDF::ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_triple(node, subject, predicate, object, graph_name = nil)
      statement = RDF::Statement.new(subject, predicate, object)
      add_error(node, "statement #{RDF::NTriples.serialize(statement)} is invalid") unless statement.valid?
      if subject && predicate && object # Basic sanity checking
        add_info(node, "statement: #{RDF::NTriples.serialize(statement)}")
        repository << statement
      end
    end

    # Parsing an RDFa document (this is *not* the recursive method)
    def parse_whole_document(doc, base)
      base = doc_base(base)
      if (base)
        # Strip any fragment from base
        base = base.to_s.split("#").first
        base = uri(base)
        add_debug("") {"parse_whole_doc: base='#{base}'"}
      end

      # initialize the evaluation context with the appropriate base
      evaluation_context = EvaluationContext.new(base, @host_defaults)

      if @version != :"rdfa1.0"
        # Process default vocabularies
        load_initial_contexts(@host_defaults[:initial_contexts]) do |which, value|
          add_debug(root) { "parse_whole_document, #{which}: #{value.inspect}"}
          case which
          when :uri_mappings        then evaluation_context.uri_mappings.merge!(value)
          when :term_mappings       then evaluation_context.term_mappings.merge!(value)
          when :default_vocabulary  then evaluation_context.default_vocabulary = value
          end
        end
      end

      traverse(root, evaluation_context)
      add_debug("", "parse_whole_doc: traversal complete'")
    end

    # Parse and process URI mappings, Term mappings and a default vocabulary from @context
    #
    # Yields each mapping
    def load_initial_contexts(initial_contexts)
      initial_contexts.
        map {|uri| uri(uri).normalize}.
        each do |uri|
          # Don't try to open ourselves!
          if base_uri == uri
            add_debug(root) {"load_initial_contexts: skip recursive context #{uri.to_base}"}
            next
          end

          old_logger = @options[:logger]
          begin
            add_info(root, "load_initial_contexts: load #{uri.to_base}")
            @options[:logger] = false
            context = Context.find(uri)

            # Add URI Mappings to prefixes
            context.prefixes.each_pair do |prefix, value|
              prefix(prefix, value)
            end
            yield :uri_mappings, context.prefixes unless context.prefixes.empty?
            yield :term_mappings, context.terms unless context.terms.empty?
            yield :default_vocabulary, context.vocabulary if context.vocabulary
          rescue Exception => e
            options[:logger] = old_logger
            add_error(root, e.message)
            raise # In case we're not in strict mode, we need to be sure processing stops
          ensure
            @options[:logger] = old_logger
          end
        end
    end

    # Extract the prefix mappings from an element
    def extract_mappings(element, uri_mappings, namespaces)
      # look for xmlns
      # (note, this may be dependent on @host_language)
      # Regardless of how the mapping is declared, the value to be mapped must be converted to lower case,
      # and the URI is not processed in any way; in particular if it is a relative path it is
      # not resolved against the current base.
      ns_defs = {}
      element.namespaces.each do |prefix, href|
        prefix = nil if prefix == "xmlns"
        add_debug("extract_mappings") { "ns: #{prefix}: #{href}"}
        ns_defs[prefix] = href
      end

      # HTML parsing doesn't create namespace_definitions
      if ns_defs.empty?
        ns_defs = {}
        element.attributes.each do |attr, href|
          next unless attr =~ /^xmlns(?:\:(.+))?/
          prefix = $1
          add_debug("extract_mappings") { "ns(attr): #{prefix}: #{href}"}
          ns_defs[prefix] = href
        end
      end

      ns_defs.each do |prefix, href|
        # A Conforming RDFa Processor must ignore any definition of a mapping for the '_' prefix.
        next if prefix == "_"
        href = uri(base_uri, href).to_s

        # Downcase prefix for RDFa 1.1
        pfx_lc = (@version == :"rdfa1.0" || prefix.nil?) ? prefix : prefix.downcase
        if prefix
          if uri_mappings.fetch(pfx_lc.to_sym, href) != href
            add_warning(element, "Redefining prefix #{pfx_lc}: from <#{uri_mappings[pfx_lc]}> to <#{href}>", RDF::RDFA.PrefixRedefinition)
          end
          uri_mappings[pfx_lc.to_sym] = href
          namespaces[pfx_lc] ||= href
          prefix(pfx_lc, href)
          add_info(element, "extract_mappings: #{prefix} => <#{href}>")
        else
          add_info(element, "extract_mappings: nil => <#{href}>")
          namespaces[""] ||= href
        end
      end

      # Set mappings from @prefix
      # prefix is a whitespace separated list of prefix-name URI pairs of the form
      #   NCName ':' ' '+ xs:anyURI
      mappings = element.attribute("prefix").to_s.strip.split(/\s+/)
      while mappings.length > 0 do
        prefix, uri = mappings.shift.downcase, mappings.shift
        #puts "uri_mappings prefix #{prefix} #{uri.to_base}"
        next unless prefix.match(/:$/)
        prefix.chop!

        unless prefix.empty? || prefix.match(NC_REGEXP)
          add_error(element, "extract_mappings: Prefix #{prefix.inspect} does not match NCName production")
          next
        end

        # A Conforming RDFa Processor must ignore any definition of a mapping for the '_' prefix.
        next if prefix == "_"
        uri = uri(base_uri, uri).to_s

        pfx_index = prefix.to_s.empty? ? nil : prefix.to_s.to_sym
        if uri_mappings.fetch(pfx_index, uri) != uri
          add_warning(element, "Redefining prefix #{prefix}: from <#{uri_mappings[pfx_index]}> to <#{uri}>", RDF::RDFA.PrefixRedefinition)
        end
        uri_mappings[pfx_index] = uri
        prefix(prefix, uri)
        add_info(element, "extract_mappings: prefix #{prefix} => <#{uri}>")
      end unless @version == :"rdfa1.0"
    end

    # The recursive helper function
    def traverse(element, evaluation_context)
      if element.nil?
        add_error(element, "Can't parse nil element")
        return nil
      end

      add_debug(element) { "ec: #{evaluation_context.inspect}" }

      # local variables [7.5 Step 1]
      recurse = true
      skip = false
      new_subject = nil
      typed_resource = nil
      current_object_resource = nil
      uri_mappings = evaluation_context.uri_mappings.clone
      namespaces = evaluation_context.namespaces.clone
      incomplete_triples = []
      language = evaluation_context.language
      term_mappings = evaluation_context.term_mappings.clone
      default_vocabulary = evaluation_context.default_vocabulary
      list_mapping = evaluation_context.list_mapping

      xml_base = element.base
      base = xml_base.to_s if xml_base && ![:xhtml1, :html4, :html5].include?(@host_language)
      add_debug(element) {"base: #{base.inspect}"} if base
      base ||= evaluation_context.base

      # Pull out the attributes needed for the skip test.
      attrs = {}
      %w(
        about
        content
        datatype
        datetime
        href
        id
        inlist
        property
        rel
        resource
        rev
        role
        src
        type
        typeof
        value
        vocab
      ).each do |a|
        attrs[a.to_sym] = element.attributes[a].to_s.strip if element.attributes[a]
      end

      add_debug(element) {"attrs " + attrs.inspect} unless attrs.empty?

      # If @property and @rel/@rev are on the same elements, the non-CURIE and non-URI @rel/@rev values are ignored. If, after this, the value of @rel/@rev becomes empty, then the then the processor must act as if the attribute is not present.
      if attrs.has_key?(:property) && @version == :"rdfa1.1" && (@host_language == :html5 || @host_language == :xhtml5 || @host_language == :html4)
        [:rel, :rev].each do |attr|
          next unless attrs.has_key?(attr)
          add_debug(element) {"Remove non-CURIE/non-IRI @#{attr} values from #{attrs[attr].inspect}"}
          attrs[attr] = attrs[attr].
            split(/\s+/).
            select {|a| a.index(':')}.
            join(" ")
          add_debug(element) {" => #{attrs[attr].inspect}"}
          attrs.delete(attr) if attrs[attr].empty?
        end
      end

      # Default vocabulary [7.5 Step 2]
      # Next the current element is examined for any change to the default vocabulary via @vocab.
      # If @vocab is present and contains a value, its value updates the local default vocabulary.
      # If the value is empty, then the local default vocabulary must be reset to the Host Language defined default.
      if attrs[:vocab]
        default_vocabulary = if attrs[:vocab].empty?
          # Set default_vocabulary to host language default
          add_debug(element) {
            "[Step 3] reset default_vocaulary to #{@host_defaults.fetch(:vocabulary, nil).inspect}"
          }
          @host_defaults.fetch(:vocabulary, nil)
        else
          # Generate a triple indicating that the vocabulary is used
          add_triple(element, base, RDF::RDFA.usesVocabulary, uri(attrs[:vocab]))

          uri(attrs[:vocab])
        end
        add_debug(element) {
          "[Step 2] default_vocaulary: #{default_vocabulary.inspect}"
        }
      end

      # Local term mappings [7.5 Step 3]
      # Next, the current element is then examined for URI mapping s and these are added to the local list of URI mappings.
      # Note that a URI mapping will simply overwrite any current mapping in the list that has the same name
      extract_mappings(element, uri_mappings, namespaces)

      # Language information [7.5 Step 4]
      language = element.language || language
      language = nil if language.to_s.empty?
      add_debug(element) {"HTML5 [3.2.3.3] lang: #{language.inspect}"} if language

      # Embedded scripts
      if element.name == 'script'
        text = element.inner_html.sub(%r(\A\s*\<!\[CDATA\[)m, '').sub(%r(\]\]>\s*\Z)m, '')

        extract_script(element, text, attrs[:type], **@options.merge(base_uri: base)) do |statement|
          @repository << statement
        end
      end

      # From HTML5, if the property attribute and the rel and/or rev attribute exists on the same element, the non-CURIE and non-URI rel and rev values are ignored. If, after this, the value of rel and/or rev becomes empty, then the processor must act as if the respective attribute is not present.
      if [:html5, :xhtml5].include?(@host_language) && attrs[:property] && (attrs[:rel] || attrs[:rev])
        old_rel, old_rev = attrs[:rel], attrs[:rev]
        if old_rel
          attrs[:rel] = (attrs[:rel]).split(/\s+/m).select {|r| !r.index(':').nil?}.join(" ")
          attrs.delete(:rel) if attrs[:rel].empty?
          add_debug(element) {"HTML5: @rel was #{old_rel}, now #{attrs[:rel]}"}
        end
        if old_rev
          attrs[:rev] = (attrs[:rev]).split(/\s+/m).select {|r| !r.index(':').nil?}.join(" ")
          attrs.delete(:rev) if attrs[:rev].empty?
          add_debug(element) {"HTML5: @rev was #{old_rev}, now #{attrs[:rev]}"}
        end
      end

      # rels and revs
      rels = process_uris(element, attrs[:rel], evaluation_context, base,
                          uri_mappings: uri_mappings,
                          term_mappings: term_mappings,
                          vocab: default_vocabulary,
                          restrictions: TERMorCURIEorAbsIRI.fetch(@version, []))
      revs = process_uris(element, attrs[:rev], evaluation_context, base,
                          uri_mappings: uri_mappings,
                          term_mappings: term_mappings,
                          vocab: default_vocabulary,
                          restrictions: TERMorCURIEorAbsIRI.fetch(@version, []))

      add_debug(element) do
        "rels: #{rels.join(" ")}, revs: #{revs.join(" ")}"
      end unless (rels + revs).empty?

      if !(attrs[:rel] || attrs[:rev])
        # Establishing a new subject if no rel/rev [7.5 Step 5]

        if @version == :"rdfa1.0"
          new_subject = if attrs[:about]
            process_uri(element, attrs[:about], evaluation_context, base,
                        uri_mappings: uri_mappings,
                        restrictions: SafeCURIEorCURIEorIRI.fetch(@version, []))
          elsif attrs[:resource]
            process_uri(element, attrs[:resource], evaluation_context, base,
                        uri_mappings: uri_mappings,
                        restrictions: SafeCURIEorCURIEorIRI.fetch(@version, []))
          elsif attrs[:href] || attrs[:src]
            process_uri(element, (attrs[:href] || attrs[:src]), evaluation_context, base, restrictions: [:uri])
          end

          # If no URI is provided by a resource attribute, then the first match from the following rules
          # will apply:
          new_subject ||= if [:xhtml1, :xhtml5, :html4, :html5].include?(@host_language) && element.name =~ /^(head|body)$/
            # From XHTML+RDFa 1.1:
            # if no URI is provided, then first check to see if the element is the head or body element.
            # If it is, then act as if the new subject is set to the parent object.
            uri(base)
          elsif element == root && base
            # if the element is the root element of the document, then act as if there is an empty @about present,
            # and process it according to the rule for @about, above;
            uri(base)
          elsif attrs[:typeof]
            RDF::Node.new
          else
            # otherwise, if parent object is present, new subject is set to the value of parent object.
            skip = true unless attrs[:property]
            evaluation_context.parent_object
          end

          # if the @typeof attribute is present, set typed resource to new subject
          typed_resource = new_subject if attrs[:typeof]
        else # rdfa1.1
          # If the current element contains no @rel or @rev attribute, then the next step is to establish a value for new subject.
          # This step has two possible alternatives.
          #  1. If the current element contains the @property attribute, but does not contain the @content or the @datatype attributes, then
          if attrs[:property] && !(attrs[:content] || attrs[:datatype])
            # new subject is set to the resource obtained from the first match from the following rule:
            new_subject ||= if attrs[:about]
              # by using the resource from @about, if present, obtained according to the section on CURIE and IRI Processing;
              process_uri(element, attrs[:about], evaluation_context, base,
                          uri_mappings: uri_mappings,
                          restrictions: SafeCURIEorCURIEorIRI.fetch(@version, []))
            elsif [:xhtml1, :xhtml5, :html4, :html5].include?(@host_language) && element.name =~ /^(head|body)$/
              # From XHTML+RDFa 1.1:
              # if no URI is provided, then first check to see if the element is the head or body element. If it is, then act as if the new subject is set to the parent object.
              evaluation_context.parent_object
            elsif element == root && base
              # otherwise, if the element is the root element of the document, then act as if there is an empty @about present, and process it according to the rule for @about, above;
              uri(base)
            end

            # if the @typeof attribute is present, set typed resource to new subject
            typed_resource = new_subject if attrs[:typeof]

            # otherwise, if parent object is present, new subject is set to the value of parent object.
            new_subject ||= evaluation_context.parent_object

            # If @typeof is present then typed resource is set to the resource obtained from the first match from the following rules:

            # by using the resource from @about, if present, obtained according to the section on CURIE and IRI Processing; (done above)
            # otherwise, if the element is the root element of the document, then act as if there is an empty @about present and process it according to the previous rule; (done above)

            if attrs[:typeof] && typed_resource.nil?
              # otherwise,
              typed_resource ||= if attrs[:resource]
                # by using the resource from @resource, if present, obtained according to the section on CURIE and IRI Processing;
                process_uri(element, attrs[:resource], evaluation_context, base,
                            uri_mappings: uri_mappings,
                            restrictions: SafeCURIEorCURIEorIRI.fetch(@version, []))
              elsif attrs[:href] || attrs[:src]
                # otherwise, by using the IRI from @href, if present, obtained according to the section on CURIE and IRI Processing;
                # otherwise, by using the IRI from @src, if present, obtained according to the section on CURIE and IRI Processing;
                process_uri(element, (attrs[:href] || attrs[:src]), evaluation_context, base,
                            restrictions: [:uri])
              else
                # otherwise, the value of typed resource is set to a newly created bnode.
                RDF::Node.new
              end

              # The value of the current object resource is set to the value of typed resource.
              current_object_resource = typed_resource
            end
          else
            # otherwise (ie, the @content or @datatype)
            new_subject =
              process_uri(element, (attrs[:about] || attrs[:resource]),
                          evaluation_context, base,
                          uri_mappings: uri_mappings,
                          restrictions: SafeCURIEorCURIEorIRI.fetch(@version, [])) if attrs[:about] ||attrs[:resource]
            new_subject ||=
              process_uri(element, (attrs[:href] || attrs[:src]), evaluation_context, base,
                          restrictions: [:uri]) if attrs[:href] || attrs[:src]

            # If no URI is provided by a resource attribute, then the first match from the following rules
            # will apply:
            new_subject ||= if [:xhtml1, :xhtml5, :html4, :html5].include?(@host_language) && element.name =~ /^(head|body)$/
              # From XHTML+RDFa 1.1:
              # if no URI is provided, then first check to see if the element is the head or body element.
              # If it is, then act as if the new subject is set to the parent object.
              evaluation_context.parent_object
            elsif element == root
              # if the element is the root element of the document, then act as if there is an empty @about present,
              # and process it according to the rule for @about, above;
              uri(base)
            elsif attrs[:typeof]
              RDF::Node.new
            else
              # otherwise, if parent object is present, new subject is set to the value of parent object.
              # Additionally, if @property is not present then the skip element flag is set to 'true'.
              skip = true unless attrs[:property]
              evaluation_context.parent_object
            end

            # If @typeof is present then typed resource is set to the resource obtained from the first match from the following rules:
            typed_resource = new_subject if attrs[:typeof]
          end
        end

        add_debug(element) {
          "[Step 5] new_subject: #{new_subject.to_ntriples rescue 'nil'}, " +
          "typed_resource: #{typed_resource.to_ntriples rescue 'nil'}, " +
          "current_object_resource: #{current_object_resource.to_ntriples rescue 'nil'}, " +
          "skip = #{skip}"
        }
      else
        # [7.5 Step 6]
        # If the current element does contain a @rel or @rev attribute, then the next step is to
        # establish both a value for new subject and a value for current object resource:
        new_subject = process_uri(element, attrs[:about], evaluation_context, base,
                                  uri_mappings: uri_mappings,
                                  restrictions: SafeCURIEorCURIEorIRI.fetch(@version, []))
        new_subject ||= process_uri(element, attrs[:src], evaluation_context, base,
                                  uri_mappings: uri_mappings,
                                  restrictions: [:uri]) if @version == :"rdfa1.0"

        # if the @typeof attribute is present, set typed resource to new subject
        typed_resource = new_subject if attrs[:typeof]

        # If no URI is provided then the first match from the following rules will apply
        new_subject ||= if element == root && base
          uri(base)
        elsif [:xhtml1, :xhtml5, :html4, :html5].include?(@host_language) && element.name =~ /^(head|body)$/
          # From XHTML+RDFa 1.1:
          # if no URI is provided, then first check to see if the element is the head or body element.
          # If it is, then act as if the new subject is set to the parent object.
          evaluation_context.parent_object
        elsif attrs[:typeof] && @version == :"rdfa1.0"
          RDF::Node.new
        else
          # if it's null, it's null and nothing changes
          evaluation_context.parent_object
          # no skip flag set this time
        end

        # Then the current object resource is set to the URI obtained from the first match from the following rules:
        current_object_resource = process_uri(element, attrs[:resource], evaluation_context, base,
                      uri_mappings: uri_mappings,
                      restrictions: SafeCURIEorCURIEorIRI.fetch(@version, [])) if attrs[:resource]
        current_object_resource ||= process_uri(element, attrs[:href], evaluation_context, base,
                      restrictions: [:uri]) if attrs[:href]
        current_object_resource ||= process_uri(element, attrs[:src], evaluation_context, base,
                      restrictions: [:uri]) if attrs[:src] && @version != :"rdfa1.0"
        current_object_resource ||= RDF::Node.new if attrs[:typeof] && !attrs[:about] && @version != :"rdfa1.0"

        # and also set the value typed resource to this bnode
        if attrs[:typeof]
          if @version == :"rdfa1.0"
            typed_resource = new_subject
          else
            typed_resource = current_object_resource if !attrs[:about]
          end
        end

        add_debug(element) {
          "[Step 6] new_subject: #{new_subject}, " +
          "current_object_resource = #{current_object_resource.nil? ? 'nil' : current_object_resource} " +
          "typed_resource: #{typed_resource.to_ntriples rescue 'nil'}, "
        }
      end

      # [Step 7] If in any of the previous steps a typed resource was set to a non-null value, it is now used to provide a subject for type values;
      if typed_resource
        # Typeof is TERMorCURIEorAbsIRIs
        types = process_uris(element, attrs[:typeof], evaluation_context, base,
                            uri_mappings: uri_mappings,
                            term_mappings: term_mappings,
                            vocab: default_vocabulary,
                            restrictions: TERMorCURIEorAbsIRI.fetch(@version, []))
        add_debug(element, "[Step 7] typeof: #{attrs[:typeof]}")
        types.each do |one_type|
          add_triple(element, typed_resource, RDF["type"], one_type)
        end
      end

      # Create new List mapping [step 8]
      #
      # If in any of the previous steps a new subject was set to a non-null value different from the parent object;
      # The list mapping taken from the evaluation context is set to a new, empty mapping.
      if (new_subject && (new_subject != evaluation_context.parent_subject || list_mapping.nil?))
        list_mapping = {}
        add_debug(element) do
          "[Step 8]: create new list mapping(#{list_mapping.object_id}) " +
            "ns: #{new_subject.to_ntriples}, " +
            "ps: #{evaluation_context.parent_subject.to_ntriples rescue 'nil'}"
        end
      end

      # Generate triples with given object [Step 9]
      #
      # If in any of the previous steps a current object resource was set to a non-null value, it is now used to generate triples and add entries to the local list mapping:
      if new_subject && current_object_resource && (attrs[:rel] || attrs[:rev])
        add_debug(element) {"[Step 9] rels: #{rels.inspect} revs: #{revs.inspect}"}
        rels.each do |r|
          if attrs[:inlist]
            # If the current list mapping does not contain a list associated with this IRI,
            # instantiate a new list
            unless list_mapping[r]
              list_mapping[r] = RDF::List.new
              add_debug(element) {"list(#{r}): create #{list_mapping[r].inspect}"}
            end
            add_debug(element) {"[Step 9] add #{current_object_resource.to_ntriples} to #{r} #{list_mapping[r].inspect}"}
            list_mapping[r] << current_object_resource
          else
            # Predicates for the current object resource can be set by using one or both of the @rel and the @rev attributes but, in case of the @rel attribute, only if the @inlist is not present:
            add_triple(element, new_subject, r, current_object_resource)
          end
        end

        revs.each do |r|
          add_triple(element, current_object_resource, r, new_subject)
        end
      elsif attrs[:rel] || attrs[:rev]
        # Incomplete triples and bnode creation [Step 10]
        add_debug(element) {"[Step 10] incompletes: rels: #{rels}, revs: #{revs}"}
        current_object_resource = RDF::Node.new

        # predicate: full IRI
        # direction: forward/reverse
        # lists: Save into list, don't generate triple

        rels.each do |r|
          if attrs[:inlist]
            # If the current list mapping does not contain a list associated with this IRI,
            # instantiate a new list
            unless list_mapping[r]
              list_mapping[r] = RDF::List.new
              add_debug(element) {"[Step 10] list(#{r}): create #{list_mapping[r].inspect}"}
            end
            incomplete_triples << {list: list_mapping[r], direction: :none}
          else
            incomplete_triples << {predicate: r, direction: :forward}
          end
        end

        revs.each do |r|
          incomplete_triples << {predicate: r, direction: :reverse}
        end
      end

      # Establish current object literal [Step 11]
      #
      # If the current element has a @inlist attribute, add the property to the
      # list associated with that property, creating a new list if necessary.
      if attrs[:property]
        properties = process_uris(element, attrs[:property], evaluation_context, base,
                                  uri_mappings: uri_mappings,
                                  term_mappings: term_mappings,
                                  vocab: default_vocabulary,
                                  restrictions: TERMorCURIEorAbsIRI.fetch(@version, []))

        properties.reject! do |p|
          if p.is_a?(RDF::URI)
            false
          else
            add_warning(element, "[Step 11] predicate #{p.to_ntriples} must be a URI")
            true
          end
        end

        datatype = process_uri(element, attrs[:datatype], evaluation_context, base,
                              uri_mappings: uri_mappings,
                              term_mappings: term_mappings,
                              vocab: default_vocabulary,
                              restrictions: TERMorCURIEorAbsIRI.fetch(@version, [])) unless attrs[:datatype].to_s.empty?
        begin
          current_property_value = case
          when datatype && ![RDF.XMLLiteral, RDF.HTML].include?(datatype)
            # typed literal
            add_debug(element, "[Step 11] typed literal (#{datatype})")
            RDF::Literal.new(attrs[:content] || attrs[:datetime] || attrs[:value] || element.inner_text.to_s, datatype: datatype, validate: validate?, canonicalize: canonicalize?)
          when @version == :"rdfa1.1"
            case
            when datatype == RDF.XMLLiteral
              # XML Literal
              add_debug(element) {"[Step 11] XML Literal: #{element.inner_html}"}

              # In order to maintain maximum portability of this literal, any children of the current node that are
              # elements must have the current in scope XML namespace declarations (if any) declared on the
              # serialized element using their respective attributes. Since the child element node could also
              # declare new XML namespaces, the RDFa Processor must be careful to merge these together when
              # generating the serialized element definition. For avoidance of doubt, any re-declarations on the
              # child node must take precedence over declarations that were active on the current node.
              begin
                c14nxl = element.children.c14nxl(
                  library: @library,
                  language: language,
                  namespaces: {nil => XHTML}.merge(namespaces))
                RDF::Literal.new(c14nxl,
                  library: @library,
                  datatype: RDF.XMLLiteral,
                  validate: validate?,
                  canonicalize: canonicalize?)
              rescue ArgumentError => e
                add_error(element, e.message)
              end
            when datatype == RDF.HTML
              # HTML Literal
              add_debug(element) {"[Step 11] HTML Literal: #{element.inner_html}"}

              # Just like XMLLiteral, but without the c14nxl
              begin
                RDF::Literal.new(element.children.to_html,
                  library: @library,
                  datatype: RDF.HTML,
                  validate: validate?,
                  canonicalize: canonicalize?)
              rescue ArgumentError => e
                add_error(element, e.message)
              end
            when attrs[:value]
              # Lexically scan value and assign appropriate type, otherwise, leave untyped
              # See https://www.w3.org/2001/sw/wiki/RDFa_1.1._Errata#Using_.3Cdata.3E.2C_.3Cinput.3E_and_.3Cli.3E_along_with_.40value
              add_debug(element, "[Step 11] value literal (#{attrs[:value]})")
              v = attrs[:value].to_s
              # Figure it out by parsing
              dt_lit = %w(Integer Decimal Double).map {|t| RDF::Literal.const_get(t)}.detect do |dt|
                v.match(dt::GRAMMAR)
              end || RDF::Literal
              dt_lit.new(v)
            when attrs[:datatype]
              # otherwise, as a plain literal if @datatype is present but has an empty value.
              # The actual literal is either the value of @content (if present) or a string created by
              # concatenating the value of all descendant text nodes, of the current element in turn.
              # typed literal
              add_debug(element, "[Step 11] datatyped literal (#{datatype})")
              RDF::Literal.new(attrs[:content] || element.inner_text.to_s, language: language, validate: validate?, canonicalize: canonicalize?)
            when attrs[:content]
              # plain literal
              add_debug(element, "[Step 11] plain literal (content)")
              RDF::Literal.new(attrs[:content], language: language, validate: validate?, canonicalize: canonicalize?)
            when element.name == 'time'
              # HTML5 support
              # Lexically scan value and assign appropriate type, otherwise, leave untyped
              v = (attrs[:content] || attrs[:datetime] || element.inner_text).to_s
              datatype = %w(Date Time DateTime Year YearMonth Duration).map {|t| RDF::Literal.const_get(t)}.detect do |dt|
                v.match(dt::GRAMMAR)
              end || RDF::Literal
              add_debug(element) {"[Step 11] <time> literal: #{datatype} #{v.inspect}"}
              datatype.new(v, language: language)
            when (attrs[:resource] || attrs[:href] || attrs[:src]) &&
                 !(attrs[:rel] || attrs[:rev]) &&
                 @version != :"rdfa1.0"
              add_debug(element, "[Step 11] resource (resource|href|src)")
              res = process_uri(element, attrs[:resource], evaluation_context, base,
                                uri_mappings: uri_mappings,
                                restrictions: SafeCURIEorCURIEorIRI.fetch(@version, [])) if attrs[:resource]
              res ||= process_uri(element, (attrs[:href] || attrs[:src]), evaluation_context, base, restrictions: [:uri])
            when typed_resource && !attrs[:about] && @version != :"rdfa1.0"
              add_debug(element, "[Step 11] typed_resource")
              typed_resource
            else
              # plain literal
              add_debug(element, "[Step 11] plain literal (inner text)")
              RDF::Literal.new(element.inner_text.to_s, language: language, validate: validate?, canonicalize: canonicalize?)
            end
          else # rdfa1.0
            if element.text_content? || (element.children.length == 0) || attrs[:datatype] == ""
              # plain literal
              add_debug(element, "[Step 11 (1.0)] plain literal")
              RDF::Literal.new(attrs[:content] || element.inner_text.to_s, language: language, validate: validate?, canonicalize: canonicalize?)
            elsif !element.text_content? and (datatype == nil or datatype == RDF.XMLLiteral)
              # XML Literal
              add_debug(element) {"[Step 11 (1.0)] XML Literal: #{element.inner_html}"}
              recurse = false
              c14nxl = element.children.c14nxl(
                library: @library,
                language: language,
                namespaces: {nil => XHTML}.merge(namespaces))
              RDF::Literal.new(c14nxl,
                library: @library,
                datatype: RDF.XMLLiteral,
                validate: validate?,
                canonicalize: canonicalize?)
            end
          end
        rescue ArgumentError => e
          add_error(element, e.message)
        end

        # add each property
        properties.each do |p|
          # Lists: If element has an @inlist attribute, add the value to a list
          if attrs[:inlist]
            # If the current list mapping does not contain a list associated with this IRI,
            # instantiate a new list
            unless list_mapping[p]
              list_mapping[p] = RDF::List.new
              add_debug(element) {"[Step 11] lists(#{p}): create #{list_mapping[p].inspect}"}
            end
            add_debug(element)  {"[Step 11] add #{current_property_value.to_ntriples} to #{p.to_ntriples} #{list_mapping[p].inspect}"}
            list_mapping[p] << current_property_value
          elsif new_subject
            add_triple(element, new_subject, p, current_property_value)
          end
        end
      end

      if !skip and new_subject && !evaluation_context.incomplete_triples.empty?
        # Complete the incomplete triples from the evaluation context [Step 12]
        add_debug(element) do
          "[Step 12] complete incomplete triples: " +
          "new_subject=#{new_subject.to_ntriples}, " +
          "completes=#{evaluation_context.incomplete_triples.inspect}"
        end

        evaluation_context.incomplete_triples.each do |trip|
          case trip[:direction]
          when :none
            add_debug(element) {"[Step 12] add #{new_subject.to_ntriples} to #{trip[:list].inspect}"}
            trip[:list] << new_subject
          when :forward
            add_triple(element, evaluation_context.parent_subject, trip[:predicate], new_subject)
          when :reverse
            add_triple(element, new_subject, trip[:predicate], evaluation_context.parent_subject)
          end
        end
      end

      # Create a new evaluation context and proceed recursively [Step 13]
      if recurse
        if skip
          if language == evaluation_context.language &&
              uri_mappings == evaluation_context.uri_mappings &&
              term_mappings == evaluation_context.term_mappings &&
              default_vocabulary == evaluation_context.default_vocabulary &&
              base == evaluation_context.base &&
              list_mapping == evaluation_context.list_mapping
            new_ec = evaluation_context
            add_debug(element, "[Step 13] skip: reused ec")
          else
            new_ec = evaluation_context.clone
            new_ec.base = base
            new_ec.language = language
            new_ec.uri_mappings = uri_mappings
            new_ec.namespaces = namespaces
            new_ec.term_mappings = term_mappings
            new_ec.default_vocabulary = default_vocabulary
            new_ec.list_mapping = list_mapping
            add_debug(element, "[Step 13] skip: cloned ec")
          end
        else
          # create a new evaluation context
          new_ec = EvaluationContext.new(base, @host_defaults)
          new_ec.parent_subject = new_subject || evaluation_context.parent_subject
          new_ec.parent_object = current_object_resource || new_subject || evaluation_context.parent_subject
          new_ec.uri_mappings = uri_mappings
          new_ec.namespaces = namespaces
          new_ec.incomplete_triples = incomplete_triples
          new_ec.language = language
          new_ec.term_mappings = term_mappings
          new_ec.default_vocabulary = default_vocabulary
          new_ec.list_mapping = list_mapping
          add_debug(element, "[Step 13] new ec")
        end

        element.children.each do |child|
          # recurse only if it's an element
          traverse(child, new_ec) if child.element?
        end

        # Step 14: after traversing through child elements, for each list associated with
        # a property
        (list_mapping || {}).each do |p, l|
          # if that list is different from the evaluation context
          ec_list = evaluation_context.list_mapping[p] if evaluation_context.list_mapping
          add_debug(element) {"[Step 14] time to create #{l.inspect}? #{(ec_list != l).inspect}"}
          if ec_list != l
            add_debug(element) {"[Step 14] list(#{p}) create #{l.inspect}"}
            # Generate an rdf:List with the elements of that list.
            l.each_statement do |st|
              add_triple(element, st.subject, st.predicate, st.object) unless st.object == RDF.List
            end

            # Generate a triple relating new_subject, property and the list BNode,
            # or rdf:nil if the list is empty.
            if l.empty?
              add_triple(element, new_subject, p, RDF.nil)
            else
              add_triple(element, new_subject, p, l.subject)
            end
          end
        end

        # Role processing
        # @id is used as subject, bnode otherwise.
        # Predicate is xhv:role
        # Objects are TERMorCURIEorAbsIRIs.
        # Act as if the default vocabulary is XHV
        if attrs[:role]
          subject = attrs[:id] ? uri(base, "##{attrs[:id]}") : RDF::Node.new
          roles = process_uris(element, attrs[:role], evaluation_context, base,
                                    uri_mappings: uri_mappings,
                                    term_mappings: term_mappings,
                                    vocab: "http://www.w3.org/1999/xhtml/vocab#",
                                    restrictions: TERMorCURIEorAbsIRI.fetch(@version, []))

          add_debug(element) {"role: about: #{subject.to_ntriples}, roles: #{roles.map(&:to_ntriples).inspect}"}
          roles.each do |r|
            add_triple(element, subject, RDF::URI("http://www.w3.org/1999/xhtml/vocab#role"), r)
          end
        end
      end
    end

    # space-separated TERMorCURIEorAbsIRI or SafeCURIEorCURIEorIRI
    def process_uris(element, value, evaluation_context, base, **options)
      return [] if value.to_s.empty?
      add_debug(element) {"process_uris: #{value}"}
      value.to_s.split(/\s+/).map {|v| process_uri(element, v, evaluation_context, base, **options)}.compact
    end

    def process_uri(element, value, evaluation_context, base, **options)
      return if value.nil?
      restrictions = options[:restrictions]
      add_debug(element) {"process_uri: #{value}, restrictions = #{restrictions.inspect}"}
      options = {uri_mappings: {}}.merge(options)
      if !options[:term_mappings] && options[:uri_mappings] && restrictions.include?(:safe_curie) && value.to_s.match(/^\[(.*)\]$/)
        # SafeCURIEorCURIEorIRI
        # When the value is surrounded by square brackets, then the content within the brackets is
        # evaluated as a CURIE according to the CURIE Syntax definition. If it is not a valid CURIE, the
        # value must be ignored.
        uri = curie_to_resource_or_bnode(element, $1, options[:uri_mappings], evaluation_context.parent_subject, restrictions)
        if uri
          add_debug(element) {"process_uri: #{value} => safeCURIE => #{uri.to_base}"}
        else
          add_warning(element, "#{value} not matched as a safeCURIE", RDF::RDFA.UnresolvedCURIE)
        end
        uri
      elsif options[:term_mappings] && TERM_REGEXP.match(value.to_s) && restrictions.include?(:term)
        # TERMorCURIEorAbsIRI
        # If the value is an NCName, then it is evaluated as a term according to General Use of Terms in
        # Attributes. Note that this step may mean that the value is to be ignored.
        uri = process_term(element, value.to_s, **options)
        add_debug(element) {"process_uri: #{value} => term => #{uri ? uri.to_base : 'nil'}"}
        uri
      else
        # SafeCURIEorCURIEorIRI or TERMorCURIEorAbsIRI
        # Otherwise, the value is evaluated as a CURIE.
        # If it is a valid CURIE, the resulting URI is used; otherwise, the value will be processed as a URI.
        uri = curie_to_resource_or_bnode(element, value, options[:uri_mappings], evaluation_context.parent_subject, restrictions)
        if uri
          add_debug(element) {"process_uri: #{value} => CURIE => #{uri.to_base}"}
        elsif @version == :"rdfa1.0" && value.to_s.match(/^xml/i)
          # Special case to not allow anything starting with XML to be treated as a URI
        elsif restrictions.include?(:absuri) || restrictions.include?(:uri)
          # AbsURI does not use xml:base
          if restrictions.include?(:absuri)
            uri = uri(value)
            unless uri.absolute?
              uri = nil
              add_warning(element, "Malformed IRI #{uri.inspect}")
            end
          else
            uri = uri(base, value)
          end
          add_debug(element) {"process_uri: #{value} => URI => #{uri ? uri.to_base : nil}"}
        end
        uri
      end
    rescue ArgumentError => e
      add_warning(element, "Malformed IRI #{value}")
    rescue RDF::ReaderError => e
      add_debug(element, e.message)
      if value.to_s =~ /^\(^\w\):/
        add_warning(element, "Undefined prefix #{$1}")
      else
        add_warning(element, "Relative URI #{value}")
      end
    end

    # [7.4.3] General Use of Terms in Attributes
    def process_term(element, value, **options)
      if options[:vocab]
        # If there is a local default vocabulary, the IRI is obtained by concatenating that value and the term
        return uri(options[:vocab] + value)
      elsif options[:term_mappings].is_a?(Hash)
        # If the term is in the local term mappings, use the associated URI (case sensitive).
        return uri(options[:term_mappings][value.to_s.to_sym]) if options[:term_mappings].has_key?(value.to_s.to_sym)

        # Otherwise, check for case-insensitive match
        options[:term_mappings].each_pair do |term, uri|
          return uri(uri) if term.to_s.downcase == value.to_s.downcase
        end
      end

      # Finally, if there is no local default vocabulary, the term has no associated URI and must be ignored.
      add_warning(element, "Term #{value} is not defined", RDF::RDFA.UnresolvedTerm)
      nil
    end

    # From section 6. CURIE Syntax Definition
    def curie_to_resource_or_bnode(element, curie, uri_mappings, subject, restrictions)
      # URI mappings for CURIEs default to XHV, rather than the default doc namespace
      prefix, reference = curie.to_s.split(":", 2)

      # consider the bnode situation
      if prefix == "_"
        # we force a non-nil name, otherwise it generates a new name
        # As a special case, _: is also a valid reference for one specific bnode.
        raise ArgumentError, "BNode not allowed in this position" unless restrictions.include?(:bnode)
        bnode(reference)
      elsif curie.to_s.match(/^:/)
        # Default prefix
        RDF::URI("http://www.w3.org/1999/xhtml/vocab#") + reference.to_s
      elsif !curie.to_s.match(/:/)
        # No prefix, undefined (in this context, it is evaluated as a term elsewhere)
        nil
      else
        # Prefixes always downcased
        prefix = prefix.to_s.downcase unless @version == :"rdfa1.0"
        add_debug(element) do
          "curie_to_resource_or_bnode check for #{prefix.to_s.to_sym.inspect} in #{uri_mappings.inspect}"
        end
        ns = uri_mappings[prefix.to_s.to_sym]
        if ns
          uri(ns + reference.to_s)
        else
          add_debug(element) {"curie_to_resource_or_bnode No namespace mapping for #{prefix.inspect}"}
          nil
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
    rescue ArgumentError => e
      raise RDF::ReaderError, e.message
    end
  end
end
