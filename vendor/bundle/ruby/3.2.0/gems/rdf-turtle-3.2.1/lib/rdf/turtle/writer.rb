require 'rdf/turtle/terminals'
require 'rdf/turtle/streaming_writer'

module RDF::Turtle
  ##
  # A Turtle serialiser
  #
  # Note that the natural interface is to write a whole graph at a time.
  # Writing statements or Triples will create a graph to add them to
  # and then serialize the graph.
  #
  # @example Obtaining a Turtle writer class
  #   RDF::Writer.for(:ttl)         #=> RDF::Turtle::Writer
  #   RDF::Writer.for("etc/test.ttl")
  #   RDF::Writer.for(file_name:       "etc/test.ttl")
  #   RDF::Writer.for(file_extension:  "ttl")
  #   RDF::Writer.for(content_type:    "text/turtle")
  #
  # @example Serializing RDF graph into an Turtle file
  #   RDF::Turtle::Writer.open("etc/test.ttl") do |writer|
  #     writer << graph
  #   end
  #
  # @example Serializing RDF statements into an Turtle file
  #   RDF::Turtle::Writer.open("etc/test.ttl") do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Serializing RDF statements into an Turtle string
  #   RDF::Turtle::Writer.buffer do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Serializing RDF statements to a string in streaming mode
  #   RDF::Turtle::Writer.buffer(stream:  true) do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # The writer will add prefix definitions, and use them for creating @prefix definitions, and minting QNames
  #
  # @example Creating @base and @prefix definitions in output
  #   RDF::Turtle::Writer.buffer(base_uri:  "http://example.com/", prefixes:  {
  #       nil => "http://example.com/ns#",
  #       foaf:  "http://xmlns.com/foaf/0.1/"}
  #   ) do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  class Writer < RDF::Writer
    include StreamingWriter
    include RDF::Util::Logger
    format RDF::Turtle::Format

    # @return [Graph] Graph of statements serialized
    attr_accessor :graph

    ##
    # Writer options
    # @see https://ruby-rdf.github.io/rdf/RDF/Writer#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :max_depth,
          datatype: Integer,
          on: ["--max-depth DEPTH"],
          description: "Maximum depth for recursively defining resources, defaults to 3.") {true},
        RDF::CLI::Option.new(
          symbol: :stream,
          datatype: TrueClass,
          on: ["--stream"],
          description: "Do not attempt to optimize graph presentation, suitable for streaming large graphs.") {true},
        RDF::CLI::Option.new(
          symbol: :default_namespace,
          datatype: RDF::URI,
          on: ["--default-namespace URI", :REQUIRED],
          description: "URI to use as default namespace, same as prefixes.") {|arg| RDF::URI(arg)},
        RDF::CLI::Option.new(
          symbol: :literal_shorthand,
          datatype: FalseClass,
          on: ["--no-literal-shorthand"],
          description: "Do not ttempt to use Literal shorthands fo numbers and boolean values.") {false},
      ]
    end

    ##
    # Initializes the Turtle writer instance.
    #
    # @param  [IO, File] output
    #   the output stream
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Encoding] :encoding     (Encoding::UTF_8)
    #   the encoding to use on the output stream
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize literals when serializing
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (not supported by all writers)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when constructing relative URIs
    # @option options [Integer]  :max_depth      (3)
    #   Maximum depth for recursively defining resources, defaults to 3
    # @option options [Boolean]  :standard_prefixes   (false)
    #   Add standard prefixes to @prefixes, if necessary.
    # @option options [Boolean] :stream (false)
    #   Do not attempt to optimize graph presentation, suitable for streaming large graphs.
    # @option options [String]   :default_namespace (nil)
    #   URI to use as default namespace, same as `prefixes[nil]`
    # @option options [Boolean]  :unique_bnodes   (false)
    #   Use unique node identifiers, defaults to using the identifier which the node was originall initialized with (if any).
    # @option options [Boolean] :literal_shorthand (true)
    #   Attempt to use Literal shorthands for numbers and boolean values
    # @yield  [writer] `self`
    # @yieldparam  [RDF::Writer] writer
    # @yieldreturn [void]
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, **options, &block)
      @graph = RDF::Graph.new
      @uri_to_pname = {}
      @uri_to_prefix = {}
      options = {literal_shorthand: true}.merge(options)
      super do
        reset
        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    ##
    # Adds a triple to be serialized
    # @param  [RDF::Resource] subject
    # @param  [RDF::URI]      predicate
    # @param  [RDF::Value]    object
    # @return [void]
    def write_triple(subject, predicate, object)
      statement = RDF::Statement.new(subject, predicate, object)
      if @options[:stream]
        stream_statement(statement)
      else
        @graph.insert(statement)
      end
    end

    ##
    # Write out declarations
    # @return [void] `self`
    def write_prologue
      case
      when @options[:stream]
        stream_prologue
      else
      end
      super
    end

    ##
    # Outputs the Turtle representation of all stored triples.
    #
    # @return [void]
    # @see    #write_triple
    def write_epilogue
      case
      when @options[:stream]
        stream_epilogue
      else
        @max_depth = @options[:max_depth] || 3

        self.reset

        log_debug("\nserialize") {"graph: #{@graph.size}"}

        preprocess

        start_document

        # Remove lists that are referenced and have non-list properties;
        # these are legal, but can't be serialized as lists
        @lists.reject! do |node, list|
          ref_count(node) > 0 && prop_count(node) > 0
        end

        order_subjects.each do |subject|
          unless is_done?(subject)
            statement(subject)
          end
        end
      end
      super
    end

    # Return a PName for the URI, or nil. Adds namespace of PName to defined prefixes
    # @param [RDF::Resource] resource
    # @return [String, nil] value to use to identify URI
    def get_pname(resource)
      case resource
      when RDF::Node
        return options[:unique_bnodes] ? resource.to_unique_base : resource.to_base
      when RDF::URI
        uri = resource.to_s
      else
        return nil
      end

      pname = case
      when @uri_to_pname.has_key?(uri)
        return @uri_to_pname[uri]
      when u = @uri_to_prefix.keys.sort_by {|uu| uu.length}.reverse.detect {|uu| uri.index(uu.to_s) == 0}
        # Use a defined prefix
        prefix = @uri_to_prefix[u]
        unless u.to_s.empty?
          prefix(prefix, u) unless u.to_s.empty?
          log_debug("get_pname") {"add prefix #{prefix.inspect} => #{u}"}
          # Escape suffix, as necessary
          RDF::URI(uri).pname(prefixes: {prefix => u})
        end
      when @options[:standard_prefixes] && vocab = RDF::Vocabulary.each.to_a.detect {|v| uri.index(v.to_uri.to_s) == 0}
        prefix = vocab.__name__.to_s.split('::').last.downcase
        @uri_to_prefix[vocab.to_uri.to_s] = prefix
        prefix(prefix, vocab.to_uri) # Define for output
        log_debug("get_pname") {"add standard prefix #{prefix.inspect} => #{vocab.to_uri}"}
        RDF::URI(uri).pname(prefixes: {prefix => vocab.to_uri})
      else
        nil
      end

      # Make sure pname is a valid pname
      if pname
        md = Terminals::PNAME_LN.match(pname) || Terminals::PNAME_NS.match(pname)
        pname = nil unless md.to_s.length == pname.length
      end

      @uri_to_pname[uri] = pname
    end

    # Take a hash from predicate uris to lists of values.
    # Sort the lists of values.  Return a sorted list of properties.
    # @param [Hash{String => Array<Resource>}] properties A hash of Property to Resource mappings
    # @return [Array<String>}] Ordered list of properties. Uses predicate_order.
    def sort_properties(properties)
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

      log_debug("sort_properties") {prop_list.join(', ')}
      prop_list
    end

    ##
    # Returns the N-Triples representation of a literal.
    #
    # @param  [RDF::Literal, String, #to_s] literal
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_literal(literal, **options)
      case literal
      when RDF::Literal
        case @options[:literal_shorthand] && literal.valid? ? literal.datatype : false
        when RDF::XSD.boolean
          %w(true false).include?(literal.value) ? literal.value : literal.canonicalize.to_s
        when RDF::XSD.integer
          literal.value.match?(/^[\+\-]?\d+$/) && !canonicalize? ? literal.value : literal.canonicalize.to_s
        when RDF::XSD.decimal
          literal.value.match?(/^[\+\-]?\d+\.\d+?$/) && !canonicalize? ?
            literal.value :
            literal.canonicalize.to_s
        when RDF::XSD.double
          in_form = case literal.value
          when /[\+\-]?\d+\.\d*E[\+\-]?\d+$/i then true
          when /[\+\-]?\.\d+E[\+\-]?\d+$/i    then true
          when /[\+\-]?\d+E[\+\-]?\d+$/i      then true
          else false
          end && !canonicalize?

          in_form ? literal.value : literal.canonicalize.to_s.sub('E', 'e').to_s
        else
          text = quoted(literal.value)
          text << "@#{literal.language}" if literal.has_language?
          text << "^^#{format_uri(literal.datatype)}" if literal.has_datatype?
          text
        end
      else
        quoted(literal.to_s)
      end
    end

    ##
    # Returns the Turtle representation of a URI reference.
    #
    # @param  [RDF::URI] uri
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_uri(uri, **options)
      md = uri.relativize(base_uri)
      log_debug("relativize") {"#{uri.to_ntriples} => #{md.inspect}"} if md != uri.to_s
      md != uri.to_s ? "<#{md}>" : (get_pname(uri) || "<#{uri}>")
    end

    ##
    # Returns the Turtle representation of a blank node.
    #
    # @param  [RDF::Node] node
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_node(node, **options)
      options[:unique_bnodes] ? node.to_unique_base : node.to_base
    end

    ##
    # Returns an embedded triple.
    #
    # @param [RDF::Statement] statement
    # @param [Hash{Symbol => Object}] options
    # @return [String]
    def format_quotedTriple(statement, **options)
      log_debug("rdfstar") {"#{statement.to_ntriples}"}
      "<<%s %s %s>>" % statement.to_a.map { |value| format_term(value, **options) }
    end

    protected
    # Output @base and @prefix definitions
    def start_document
      @output.write("#{indent}@base <#{base_uri}> .\n") unless base_uri.to_s.empty?

      log_debug("start_document") {prefixes.inspect}
      prefixes.keys.sort_by(&:to_s).each do |prefix|
        @output.write("#{indent}@prefix #{prefix}: <#{prefixes[prefix]}> .\n")
      end
    end

    # Defines rdf:type of subjects to be emitted at the beginning of the graph. Defaults to rdfs:Class
    # @return [Array<URI>]
    def top_classes; [RDF::RDFS.Class]; end

    # Defines order of predicates to to emit at begninning of a resource description. Defaults to
    # `\[rdf:type, rdfs:label, dc:title\]`
    # @return [Array<URI>]
    def predicate_order; [RDF.type, RDF::RDFS.label, RDF::URI("http://purl.org/dc/terms/title")]; end

    # Order subjects for output. Override this to output subjects in another order.
    #
    # Uses #top_classes and #base_uri.
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      seen = {}
      subjects = []

      # Start with base_uri
      if base_uri && @subjects.keys.include?(base_uri)
        subjects << RDF::URI(base_uri)
        seen[RDF::URI(base_uri)] = true
      end

      # Add distinguished classes
      top_classes.each do |class_uri|
        graph.query({predicate:  RDF.type, object:  class_uri}).
          map {|st| st.subject}.
          sort.
          uniq.
          each do |subject|
          log_debug("order_subjects") {subject.to_ntriples}
          subjects << subject
          seen[subject] = true
        end
      end

      # Mark as seen lists that are part of another list
      @lists.values.map(&:statements).
        flatten.each do |st|
          seen[st.object] = true if @lists.key?(st.object)
        end

      # List elements which are bnodes should not be targets for top-level serialization
      list_elements = @lists.values.map(&:to_a).flatten.select(&:node?).compact

      # Sort subjects by resources and statements over bnodes, ref_counts and the subject URI itself
      recursable = (@subjects.keys - list_elements).
        select {|s| !seen.include?(s)}.
        map {|r| [r.node? ? 2 : (r.statement? ? 1 : 0), ref_count(r), r]}.
        sort

      subjects + recursable.map{|r| r.last}
    end

    # Perform any preprocessing of statements required
    def preprocess
      # Load defined prefixes
      (@options[:prefixes] || {}).each_pair do |k, v|
        @uri_to_prefix[v.to_s] = k
      end

      prefix(nil, @options[:default_namespace]) if @options[:default_namespace]

      case
      when @options[:stream]
      else
        @options[:prefixes] = {}  # Will define actual used when matched

        @graph.each {|statement| preprocess_statement(statement)}
      end
    end

    # Perform any statement preprocessing required. This is used to perform reference counts and determine required
    # prefixes.
    # @param [Statement] statement
    def preprocess_statement(statement)
      #log_debug("preprocess") {statement.to_ntriples}
      bump_reference(statement.object)
      # Count properties of this subject
      (@subjects[statement.subject] ||= {})[statement.predicate] ||= 0
      @subjects[statement.subject][statement.predicate] += 1

      # Collect lists
      if statement.predicate == RDF.first
        l = RDF::List.new(subject: statement.subject, graph: graph)
        @lists[statement.subject] = l if l.valid?
      end

      if statement.object == RDF.nil || statement.subject == RDF.nil
        # Add an entry for the list tail
        @lists[RDF.nil] ||= RDF::List[]
      end

      # Pre-fetch pnames, to fill prefixes
      get_pname(statement.subject)
      get_pname(statement.predicate)
      get_pname(statement.object)
      get_pname(statement.object.datatype) if statement.object.literal? && statement.object.datatype
    end

    # Returns indent string multiplied by the depth
    # @param [Integer] modifier Increase depth by specified amount
    # @return [String] A number of spaces, depending on current depth
    def indent(modifier = 0)
      " " * (@options.fetch(:log_depth, log_depth) * 2 + modifier)
    end

    # Reset internal helper instance variables
    def reset
      @lists = {}

      @references = {}
      @serialized = {}
      @subjects = {}
    end

    ##
    # Use single- or multi-line quotes. If literal contains \t, \n, or \r, use a multiline quote,
    # otherwise, use a single-line
    # @param  [String] string
    # @return [String]
    def quoted(string)
      if string.to_s.match(/[\t\n\r]/)
        string = string.gsub('\\', '\\\\\\\\').gsub('"', '\\"')

        %("""#{string}""")
      else
        "\"#{escaped(string)}\""
      end
    end

    # Can subject be represented as a blankNodePropertyList?
    def blankNodePropertyList?(resource, position)
      !resource.statement? && resource.node? &&
        !collection?(resource) &&
        (!is_done?(resource) || position == :subject) &&
        ref_count(resource) == (position == :object ? 1 : 0)
    end

    # Return the number of statements having this resource as a subject other than for list properties
    # @return [Integer]
    def prop_count(subject)
      @subjects.fetch(subject, {}).
        reject {|k, v| [RDF.type, RDF.first, RDF.rest].include?(k)}.
        values.reduce(:+) || 0
    end

    # Return the number of times this node has been referenced in the object position
    # @return [Integer]
    def ref_count(resource)
      @references.fetch(resource, 0)
    end

    # Increase the reference count of this resource
    # @param [RDF::Resource] resource
    # @return [Integer] resulting reference count
    def bump_reference(resource)
      @references[resource] = ref_count(resource) + 1
    end

    def is_done?(subject)
      @serialized.include?(subject)
    end

    # Mark a subject as done.
    def subject_done(subject)
      @serialized[subject] = true
    end

    private

    # Checks if l is a valid RDF list, i.e. no nodes have other properties.
    def collection?(l)
      #log_debug("collection?") {l.inspect}
      return @lists.key?(l)
    end

    def collection(node, position)
      return false if !collection?(node)
      return false if position == :subject && ref_count(node) > 0
      return false if position == :object && prop_count(node) > 0
      #log_debug("collection") {"#{node.to_ntriples}, #{position}"}

      @output.write("(")
      log_depth do
        list = @lists[node]
        log_debug("collection") {list.inspect}
        subject_done(RDF.nil)
        index = 0
        list.each_statement do |st|
          next unless st.predicate == RDF.first
          log_debug {" list this: #{st.subject} first: #{st.object}[#{position}]"}
          @output.write(" ") if index > 0
          path(st.object, position)
          subject_done(st.subject)
          position = :object
          index += 1
        end
      end
      @output.write(')')
    end

    # Represent resource as a blankNodePropertyList
    def blankNodePropertyList(resource, position)
      return false unless blankNodePropertyList?(resource, position)

      log_debug("blankNodePropertyList") {resource.to_ntriples}
      subject_done(resource)
      @output.write(position == :subject ? "\n#{indent} [" : '[')
      num_props = log_depth {predicateObjectList(resource, true)}
      @output.write((num_props > 1 ? "\n#{indent(2)}" : "") + (position == :object ? ']' : '] .'))
      true
    end

    # Default singular resource representation.
    def p_term(resource, position)
      #log_debug("p_term") {"#{resource.to_ntriples}, #{position}"}
      l = if resource == RDF.nil
        "()"
      else
        format_term(resource, **options)
      end
      @output.write(l)
    end

    # Represent a resource in subject, predicate or object position.
    # Use either collection, blankNodePropertyList or singular resource notation.
    def path(resource, position)
      log_debug("path") do
        "#{resource.to_ntriples}, " +
        "pos: #{position}, " +
        "()?: #{collection?(resource)}, " +
        "[]?: #{blankNodePropertyList?(resource, position)}, " +
        "rc: #{ref_count(resource)}"
      end
      raise RDF::WriterError, "Cannot serialize resource '#{resource}'" unless
        collection(resource, position) ||
        blankNodePropertyList(resource, position) ||
        p_term(resource, position)
    end

    def predicate(resource)
      log_debug("predicate") {resource.to_ntriples}
      if resource == RDF.type
        @output.write("a")
      else
        path(resource, :predicate)
      end
    end

    # Render an objectList having a common subject and predicate
    def objectList(subject, predicate, objects)
      log_debug("objectList") {objects.inspect}
      return if objects.empty?

      objects.each_with_index do |obj, i|
        if i > 0 && blankNodePropertyList?(obj, :object)
          @output.write ", "
        elsif i > 0
          @output.write ",\n#{indent(4)}"
        end
        path(obj, :object)

        # If subject, predicate, and object are embedded, write those bits out too.
        emb = RDF::Statement(subject, predicate, obj)
        if !@graph.query({subject: emb}).empty?
          @output.write ' {| '
          predicateObjectList(emb, true)
          @output.write ' |}'
          subject_done(emb)
        end
      end
    end

    # Render a predicateObjectList having a common subject.
    # @return [Integer] the number of properties serialized
    def predicateObjectList(subject, from_bpl = false)
      properties = {}
      @graph.query({subject:  subject}) do |st|
        (properties[st.predicate.to_s] ||= []) << st.object
      end

      prop_list = sort_properties(properties)
      prop_list -= [RDF.first.to_s, RDF.rest.to_s] if @lists.key?(subject)
      log_debug("predicateObjectList") {prop_list.inspect}
      return 0 if prop_list.empty?

      @output.write("\n#{indent(2)}") if properties.keys.length > 1 && from_bpl
      prop_list.each_with_index do |prop, i|
        begin
          pred = RDF::URI.intern(prop)
          @output.write(";\n#{indent(2)}") if i > 0
          predicate(pred)
          @output.write(" ")
          objectList(subject, pred, properties[prop])
        end
      end
      properties.keys.length
    end

    # Render triples having the same subject using an explicit subject
    def triples(subject)
      @output.write("\n#{indent}")
      path(subject, :subject)
      @output.write(" ")
      num_props = predicateObjectList(subject)
      @output.write("#{num_props > 0 ? ' ' : ''}.")
      true
    end

    def statement(subject)
      log_debug("statement") {"#{subject.to_ntriples}, bnodePL?: #{blankNodePropertyList?(subject, :subject)}"}
      subject_done(subject)
      blankNodePropertyList(subject, :subject) || triples(subject)
      @output.puts
    end
  end
end
