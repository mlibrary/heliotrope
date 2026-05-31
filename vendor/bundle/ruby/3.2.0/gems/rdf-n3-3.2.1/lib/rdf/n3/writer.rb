# coding: utf-8
module RDF::N3
  ##
  # A Notation-3 serialiser in Ruby
  #
  # Note that the natural interface is to write a whole graph at a time.
  # Writing statements or Triples will create a graph to add them to
  # and then serialize the graph.
  #
  # @example Obtaining a N3 writer class
  #   RDF::Writer.for(:n3)         #=> RDF::N3::Writer
  #   RDF::Writer.for("etc/test.n3")
  #   RDF::Writer.for(file_name:      "etc/test.n3")
  #   RDF::Writer.for(file_extension: "n3")
  #   RDF::Writer.for(content_type:   "text/n3")
  #
  # @example Serializing RDF graph into an N3 file
  #   RDF::N3::Writer.open("etc/test.n3") do |writer|
  #     writer << graph
  #   end
  #
  # @example Serializing RDF statements into an N3 file
  #   RDF::N3::Writer.open("etc/test.n3") do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Serializing RDF statements into an N3 string
  #   RDF::N3::Writer.buffer do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # The writer will add prefix definitions, and use them for creating @prefix definitions, and minting pnames
  #
  # @example Creating @base and @prefix definitions in output
  #   RDF::N3::Writer.buffer(base_uri: "http://example.com/", prefixes: {
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
    format RDF::N3::Format
    include RDF::Util::Logger
    include Terminals
    using Refinements

    # @return [RDF::Repository] Repository of statements serialized
    attr_accessor :repo

    # @return [RDF::Graph] Graph being serialized
    attr_accessor :graph

    # @return [Array<RDF::Node>] formulae names
    attr_accessor :formula_names

    ##
    # N3 Writer options
    # @see https://ruby-rdf.github.io/rdf/RDF/Writer#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :max_depth,
          datatype: Integer,
          on: ["--max-depth"],
          description: "Maximum depth for recursively defining resources, defaults to 3.") {|arg| arg.to_i},
        RDF::CLI::Option.new(
          symbol: :default_namespace,
          datatype: RDF::URI,
          on: ["--default-namespace URI", :REQUIRED],
          description: "URI to use as default namespace, same as prefixes.") {|arg| RDF::URI(arg)},
      ]
    end

    ##
    # Initializes the N3 writer instance.
    #
    # @param  [IO, File] output
    #   the output stream
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Encoding] :encoding     (Encoding::UTF_8)
    #   the encoding to use on the output stream (Ruby 1.9+)
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
    # @option options [String]   :default_namespace (nil)
    #   URI to use as default namespace, same as prefixes[nil]
    # @option options [Boolean]  :unique_bnodes   (false)
    #   Use unique node identifiers, defaults to using the identifier which the node was originall initialized with (if any).
    # @yield  [writer] `self`
    # @yieldparam  [RDF::Writer] writer
    # @yieldreturn [void]
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, **options, &block)
      @repo = RDF::N3::Repository.new
      @uri_to_pname = {}
      @uri_to_prefix = {}
      super do
        if base_uri
          @uri_to_prefix[base_uri.to_s.end_with?('#', '/') ? base_uri : RDF::URI("#{base_uri}#")] = nil
        end
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
    # Addes a triple to be serialized
    # @param  [RDF::Resource] subject
    # @param  [RDF::URI]      predicate
    # @param  [RDF::Value]    object
    # @return [void]
    # @raise  [NotImplementedError] unless implemented in subclass
    # @abstract
    def write_triple(subject, predicate, object)
      repo.insert(RDF::Statement(subject, predicate, object))
    end

    ##
    # Adds a quad to be serialized
    # @param  [RDF::Resource] subject
    # @param  [RDF::URI]      predicate
    # @param  [RDF::Value]    object
    # @param  [RDF::Resource] graph_name
    # @return [void]
    def write_quad(subject, predicate, object, graph_name)
      statement = RDF::Statement.new(subject, predicate, object, graph_name: graph_name)
      repo.insert(statement)
    end

    ##
    # Outputs the N3 representation of all stored triples.
    #
    # @return [void]
    # @see    #write_triple
    def write_epilogue
      @max_depth = @options[:max_depth] || 3

      self.reset

      log_debug("\nserialize: repo:") {repo.size}

      preprocess

      start_document

      @formula_names = repo.graph_names(unique: true)

      with_graph(nil) do
        count = 0
        order_subjects.each do |subject|
          unless is_done?(subject)
            statement(subject, count)
            count += 1
          end
        end

        # Output any formulae not already serialized using owl:sameAs
        formula_names.each do |graph_name|
          next if graph_done?(graph_name)

          # Add graph_name to @formulae
          @formulae[graph_name] = true

          log_debug {"formula(#{graph_name})"}
          @output.write("\n#{indent}")
          p_term(graph_name, :subject)
          @output.write(" ")
          predicate(RDF::OWL.sameAs)
          @output.write(" ")
          formula(graph_name, :graph_name)
          @output.write(" .\n")
        end
      end

      super
    end

    # Return a pname for the URI, or nil. Adds namespace of pname to defined prefixes
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

      #log_debug {"get_pname(#{resource}), std?}"}
      pname = case
      when @uri_to_pname.key?(uri)
        return @uri_to_pname[uri]
      when u = @uri_to_prefix.keys.detect {|u| uri.index(u.to_s) == 0}
        # Use a defined prefix
        prefix = @uri_to_prefix[u]
        unless u.to_s.empty?
          prefix(prefix, u) unless u.to_s.empty?
          #log_debug("get_pname") {"add prefix #{prefix.inspect} => #{u}"}
          uri.sub(u.to_s, "#{prefix}:")
        end
      when @options[:standard_prefixes] && vocab = RDF::Vocabulary.each.to_a.detect {|v| uri.index(v.to_uri.to_s) == 0}
        prefix = vocab.__name__.to_s.split('::').last.downcase
        @uri_to_prefix[vocab.to_uri.to_s] = prefix
        prefix(prefix, vocab.to_uri) # Define for output
        #log_debug {"get_pname: add standard prefix #{prefix.inspect} => #{vocab.to_uri}"}
        uri.sub(vocab.to_uri.to_s, "#{prefix}:")
      else
        nil
      end

      # Make sure pname is a valid pname
      if pname
        md = PNAME_LN.match(pname) || PNAME_NS.match(pname)
        pname = nil unless md.to_s.length == pname.length
      end

      @uri_to_pname[uri] = pname
    end

    # Take a hash from predicate uris to lists of values.
    # Sort the lists of values.  Return a sorted list of properties.
    # @param [Hash{RDF::Term => Array<RDF::Term>}] properties A hash of Property to Resource mappings
    # @return [Array<RDF::Term>}] Ordered list of properties. Uses predicate_order.
    def sort_properties(properties)
      # Make sorted list of properties
      prop_list = []

      predicate_order.each do |prop|
        next unless properties.key?(prop)
        prop_list << prop
      end

      properties.keys.sort.each do |prop|
        next if prop_list.include?(prop)
        prop_list << prop
      end

      prop_list
    end

    ##
    # Returns the N-Triples representation of a literal.
    #
    # @param  [RDF::Literal, String, #to_s] literal
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_literal(literal, **options)
      literal = literal.dup.canonicalize! if @options[:canonicalize]
      case literal
      when RDF::Literal
        case literal.valid? ? literal.datatype : false
        when RDF::XSD.boolean
          %w(true false).include?(literal.value) ? literal.value : literal.canonicalize.to_s
        when RDF::XSD.integer
          literal.value.match?(/^[\+\-]?\d+$/) && !canonicalize? ? literal.value : literal.canonicalize.to_s
        when RDF::XSD.decimal
          literal.value.match?(/^[\+\-]?\d+\.\d+?$/) && !canonicalize? ?
            literal.value :
            literal.canonicalize.to_s
        when RDF::XSD.double
          if literal.nan? || literal.infinite?
            quoted(literal.value) + "^^#{format_uri(literal.datatype)}"
          else
            in_form = case literal.value
            when /[\+\-]?\d+\.\d*E[\+\-]?\d+$/i then true
            when /[\+\-]?\.\d+E[\+\-]?\d+$/i    then true
            when /[\+\-]?\d+E[\+\-]?\d+$/i      then true
            else false
            end && !canonicalize?

            in_form ? literal.value : literal.canonicalize.to_s.sub('E', 'e')
          end
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
    # Returns the N3 representation of a URI reference.
    #
    # @param  [RDF::URI] uri
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_uri(uri, **options)
      md = uri == base_uri ? '' : uri.relativize(base_uri)
      log_debug("relativize") {"#{uri.to_sxp} => <#{md.inspect}>"} if md != uri.to_s
      md != uri.to_s ? "<#{md}>" : (get_pname(uri) || "<#{uri}>")
    end

    ##
    # Returns the N3 representation of a blank node.
    #
    # @param  [RDF::Node] node
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_node(node, **options)
      if node.id.match(/^([^_]+)_[^_]+_([^_]+)$/)
        sn, seq = $1, $2.to_i
        seq = nil if seq == 0
        "_:#{sn}#{seq}"
      elsif options[:unique_bnodes]
        node.to_unique_base
      else
        node.to_base
      end
    end

    protected
    # Output @base and @prefix definitions
    def start_document
      @output.write("@base <#{base_uri}> .\n") unless base_uri.to_s.empty?

      log_debug("start_document: prefixes") { prefixes.inspect}
      prefixes.keys.sort_by(&:to_s).each do |prefix|
        @output.write("@prefix #{prefix}: <#{prefixes[prefix]}> .\n")
      end
    end

    # Defines rdf:type of subjects to be emitted at the beginning of the graph. Defaults to rdfs:Class
    # @return [Array<URI>]
    def top_classes; [RDF::RDFS.Class]; end

    # Defines order of predicates to to emit at begninning of a resource description. Defaults to
    # [rdf:type, rdfs:label, dc:title]
    # @return [Array<URI>]
    def predicate_order
      [
        RDF.type,
        RDF::RDFS.label,
        RDF::RDFS.comment,
        RDF::URI("http://purl.org/dc/terms/title"),
        RDF::URI("http://purl.org/dc/terms/description"),
        RDF::OWL.sameAs,
        RDF::N3::Log.implies
      ]
    end

    # Order subjects for output. Override this to output subjects in another order.
    #
    # Uses #top_classes and #base_uri.
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      seen = {}
      subjects = []

      # Start with base_uri
      if base_uri && @subjects.keys.select(&:uri?).include?(base_uri)
        subjects << base_uri
        seen[base_uri] = true
      end

      # Add distinguished classes
      top_classes.each do |class_uri|
        graph.query({predicate: RDF.type, object: class_uri}).
          map {|st| st.subject}.sort.uniq.each do |subject|
            log_debug("order_subjects") {subject.to_sxp}
            subjects << subject
            seen[subject] = true
          end
      end

      # Add formulae which are subjects in this graph
      @formulae.each_key do |bn|
        next unless @subjects.key?(bn)
        subjects << bn
        seen[bn] = true
      end

      # Mark as seen lists that are part of another list
      @lists.values.flatten.each do |v|
        seen[v] = true if @lists.key?(v)
      end

      list_elements = []  # Lists may be top-level elements

      # Sort subjects by resources over bnodes, ref_counts and the subject URI itself
      recursable = (@subjects.keys - list_elements).
        select {|s| !seen.include?(s)}.
        map {|r| [r.node? ? 1 : 0, ref_count(r), r]}.
        sort

      subjects += recursable.map{|r| r.last}
    end

    # Perform any preprocessing of statements required
    def preprocess
      # Load defined prefixes
      (@options[:prefixes] || {}).each_pair do |k, v|
        @uri_to_prefix[v.to_s] = k
      end
      @options[:prefixes] = {}  # Will define actual used when matched

      prefix(nil, @options[:default_namespace]) if @options[:default_namespace]

      @options[:prefixes] = {}  # Will define actual used when matched
      repo.each {|statement| preprocess_statement(statement)}
    end

    # Perform any statement preprocessing required. This is used to perform reference counts and determine required
    # prefixes.
    # @param [Statement] statement
    def preprocess_statement(statement)
      #log_debug("preprocess") {statement.inspect}

      # Pre-fetch pnames, to fill prefixes
      get_pname(statement.subject)
      get_pname(statement.predicate)
      get_pname(statement.object)
      get_pname(statement.object.datatype) if statement.object.literal? && statement.object.datatype
    end

    # Perform graph-specific preprocessing
    # @param [Statement] statement
    def preprocess_graph_statement(statement)
      bump_reference(statement.object)
      # Count properties of this subject
      @subjects[statement.subject] ||= {}
      @subjects[statement.subject][statement.predicate] ||= 0
      @subjects[statement.subject][statement.predicate] += 1
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
      @graphs = {}
      @subjects = {}
    end

    ##
    # Use single- or multi-line quotes. If literal contains \t, \n, or \r, use a multiline quote,
    # otherwise, use a single-line
    # @param  [String] string
    # @return [String]
    def quoted(string)
      if string.to_s.match(/[\t\n\r]/)
        string = string.gsub('\\', '\\\\\\\\').gsub('"""', '\\"\\"\\"')
        %("""#{string}""")
      else
        "\"#{escaped(string)}\""
      end
    end

    private

    # Checks if l is a valid RDF list, i.e. no nodes have other properties.
    def collection?(l)
      return @lists.key?(l) || l.list?
    end

    def collection(node, position)
      return false if !collection?(node)
      log_debug("collection") do
        "#{node.to_sxp}, " +
        "pos: #{position}, " +
        "rc: #{ref_count(node)}"
      end

      @output.write("(")
      log_depth do
        list = node.list? ? node : @lists[node]
        log_debug("collection") {list.inspect}
        subject_done(RDF.nil)
        subject_done(node)
        index = 0
        list.each do |li|
          log_debug("(list first)") {"#{li}[#{position}]"}
          @output.write(" ") if index > 0
          path(li, :object)
          subject_done(li)
          index += 1
        end
      end
      @output.write(')')
    end

    # Default singular resource representation.
    def p_term(resource, position)
      #log_debug("p_term") {"#{resource.to_sxp}, #{position}"}
      l = if resource.is_a?(RDF::Query::Variable)
        "?#{resource.name}"
      elsif resource == RDF.nil
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
        "#{resource.to_sxp}, " +
        "pos: #{position}, " +
        "{}?: #{formula?(resource, position).inspect}, " +
        "()?: #{collection?(resource).inspect}, " +
        "[]?: #{blankNodePropertyList?(resource, position).inspect}, " +
        "rc: #{ref_count(resource)}"
      end
      raise RDF::WriterError, "Cannot serialize resource '#{resource}'" unless
        formula(resource, position) ||
        collection(resource, position) ||
        blankNodePropertyList(resource, position) ||
        p_term(resource, position)
    end

    def predicate(resource)
      log_debug("predicate") {resource.to_sxp}
      case resource
      when RDF.type
        @output.write("a")
      when RDF::OWL.sameAs
        @output.write("=")
      when RDF::N3::Log.implies
        @output.write("=>")
      else
        log_depth {path(resource, :predicate)}
      end
    end

    # Render an objectList having a common subject and predicate
    def objectList(objects)
      log_debug("objectList") {objects.inspect}
      return if objects.empty?

      log_depth do
        objects.each_with_index do |obj, i|
          if i > 0 && (formula?(obj, :object) || blankNodePropertyList?(obj, :object))
            @output.write ", "
          elsif i > 0
            @output.write ",\n#{indent(4)}"
          end
          path(obj, :object)
        end
      end
    end

    # Render a predicateObjectList having a common subject.
    # @return [Integer] the number of properties serialized
    def predicateObjectList(subject, from_bpl = false)
      properties = {}
      @graph.enum_statement.select {|s| s.subject.sameTerm?(subject)}.each do |st|
        (properties[st.predicate] ||= []) << st.object
      end

      prop_list = sort_properties(properties)
      prop_list -= [RDF.first, RDF.rest] if @lists.key?(subject)
      log_debug("predicateObjectList") { "subject: #{subject.to_sxp}, properties: #{prop_list.join(', ')}" }
      return 0 if prop_list.empty?

      @output.write("\n#{indent(2)}") if properties.keys.length > 1 && from_bpl
      log_depth do
        prop_list.each_with_index do |prop, i|
          begin
            @output.write(";\n#{indent(2)}") if i > 0
            predicate(prop)
            @output.write(" ")
            objectList(properties[prop])
          end
        end
      end
      properties.keys.length
    end

    # Can subject be represented as a blankNodePropertyList?
    def blankNodePropertyList?(resource, position)
      resource.node? &&
        !formula?(resource, position) &&
        !collection?(resource) &&
        (!is_done?(resource) || position == :subject) &&
        ref_count(resource) == (position == :object ? 1 : 0) &&
        !repo.has_graph?(resource)
    end

    def blankNodePropertyList(resource, position)
      return false unless blankNodePropertyList?(resource, position)

      log_debug("blankNodePropertyList") {resource.to_sxp}
      subject_done(resource)
      @output.write((position == :subject ? "\n#{indent}[" : '['))
      num_props = log_depth {predicateObjectList(resource, true)}
      @output.write((num_props > 1 ? "\n#{indent(2)}" : "") + (position == :subject ? '] .' : ']'))
      true
    end

    # Can subject be represented as a formula?
    def formula?(resource, position)
      !!@formulae[resource]
    end

    def formula(resource, position)
      return false unless formula?(resource, position)

      log_debug("formula") {resource.to_sxp}
      subject_done(resource)
      @output.write('{')
      count = 0
      log_depth do
        with_graph(resource) do
          order_subjects.each do |subject|
            unless is_done?(subject)
              statement(subject, count)
              count += 1
            end
          end
        end
      end
      @output.write((count > 0 ? "#{indent}" : "") + '}')
      true
    end

    # Render triples having the same subject using an explicit subject
    def triples(subject)
      @output.write("\n#{indent}")
      path(subject, :subject)
      @output.write(" ")
      num_props = predicateObjectList(subject)
      @output.puts("#{num_props > 0 ? ' ' : ''}.")
      true
    end

    def statement(subject, count)
      log_debug("statement") do
        "#{subject.to_sxp}, " +
        "{}?: #{formula?(subject, :subject).inspect}, " +
        "()?: #{collection?(subject).inspect}, " +
        "[]?: #{blankNodePropertyList?(subject, :subject).inspect}, "
      end
      subject_done(subject)
      blankNodePropertyList(subject, :subject) || triples(subject)
      @output.puts if count > 0 || graph.graph_name
    end

    # Return the number of times this node has been referenced in the object position
    # @return [Integer]
    def ref_count(node)
      @references.fetch(node, 0)
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

    def graph_done?(subject)
       @graphs.include?(subject)
    end

    # Mark a graph as done.
    def graph_done(graph_name)
      @graphs[graph_name] = true
    end

    # Process a graph projection
    def with_graph(graph_name)
      old_lists, @lists = @lists, {}
      old_references, @references = @references, {}
      old_serialized, @serialized = @serialized, {}
      old_subjects, @subjects = @subjects, {}
      old_graph, @graph = @graph, repo.project_graph(graph_name)
      old_formulae, @formulae = @formulae, {}

      graph_done(graph_name)

      lists = {}
      graph.each do |statement|
        preprocess_graph_statement(statement)
        [statement.subject, statement.object].each do |resource|
          @formulae[resource] = true if
            resource.node? &&
            (formula_names.include?(resource) || resource.id.start_with?('_form_'))

          # First-class list may have members which are formulae, and need reference counts
          if resource.list?
            resource.each_descendant do |term|
              bump_reference(term)
              @formulae[term] = true if
                term.node? &&
                (formula_names.include?(term) || term.id.start_with?('_form_'))
            end
          end
        end

        # Collect list elements
        if [RDF.first, RDF.rest].include?(statement.predicate) && statement.subject.node?
          lists[statement.subject] ||= {}
          lists[statement.subject][statement.predicate] = statement.object
        end
      end

      # Remove list entries after head with more than two properties (other than rdf:type)
      rests = lists.values.map {|props| props[RDF.rest]}

      # Remove non-head lists that have too many properties
      rests.select do |bn|
        pc = 0
        @subjects.fetch(bn, {}).each do |pred, count|
          next if pred == RDF.type
          pc += count
        end
        lists.delete(bn) if pc > 2
      end

      # Values for this list element, recursive
      def list_values(bn, lists)
        raise "no list" unless lists.has_key?(bn)
        first, rest = lists[bn][RDF.first], lists[bn][RDF.rest]
        (rest == RDF.nil ? [] : list_values(rest, lists)).unshift(first)
      rescue
        lists.delete(bn)
        raise $!
      end

      # Create value arrays for each entry
      lists.each do |bn, props|
        begin
          @lists[bn] = list_values(bn, lists)
        rescue
          # Skip this list element, if it raises an exception
          lists.delete(bn)
        end
      end

      # Mark all remaining rests done
      rests.each {|bn| subject_done(bn) if lists.include?(bn)}

      # Remove entries that are referenced as rdf:rest of some entry
      lists.each do |bn, props|
        @lists.delete(props[RDF.rest])
      end

      # Record nodes in subject or object
      yield
    ensure
      @graph, @lists, @references, @serialized, @subjects, @formulae = old_graph, old_lists, old_references, old_serialized, old_subjects, old_formulae
    end
  end
end
