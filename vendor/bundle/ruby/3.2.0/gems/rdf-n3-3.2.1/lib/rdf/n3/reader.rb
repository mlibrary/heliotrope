# coding: utf-8
require 'rdf/reader'
require 'ebnf'

module RDF::N3
  ##
  # A Notation-3/Turtle parser in Ruby
  #
  # N3 Parser, based in librdf version of predictiveParser.py
  # @see http://www.w3.org/2000/10/swap/grammar/predictiveParser.py
  # @see http://www.w3.org/2000/10/swap/grammar/n3-selectors.n3
  #
  # Separate pass to create branch_table from n3-selectors.n3
  #
  # This implementation only supports quickVars at the document scope.
  #
  # Non-distinguished blank node variables are created as part of reasoning.
  #
  # @todo
  # * Formulae as RDF::Query representations
  # * Formula expansion similar to SPARQL Construct
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class Reader < RDF::Reader
    format Format
    using Refinements

    include RDF::Util::Logger
    include EBNF::LL1::Parser
    include Terminals

    # Nodes used as Formulae graph names
    #
    # @return [Array<RDF::Node>]
    attr_reader :formulae

    # All nodes allocated to formulae
    #
    # @return [Hash{RDF::Node => RDF::Graph}]
    attr_reader :formula_nodes

    # Allocated variables by formula
    #
    # @return [Hash{Symbol => RDF::Node}]
    attr_reader :variables

    ##
    # N3 Reader options
    # @see https://ruby-rdf.github.io/rdf/RDF/Reader#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :list_terms,
          datatype: TrueClass,
          default: true,
          control: :checkbox,
          on: ["--list-terms CONTEXT"],
          description: "Use native collections (lists), not first/rest ladder.")
      ]
    end

    ##
    # Initializes the N3 reader instance.
    #
    # @param  [IO, File, String] input
    #   the input stream to read
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (not supported by
    #   all readers)
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize parsed literals and URIs.
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (not supported by all readers)
    # @option options [Hash]     :list_terms   (false)
    #   represent collections as an `RDF::Term`, rather than an rdf:first/rest ladder.
    # @return [reader]
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [Error]:: Raises RDF::ReaderError if validating and an error is found
    def initialize(input = $stdin, **options, &block)
      super do
        @options = {
          anon_base:  "b0",
          whitespace:  WS,
          depth: 0,
        }.merge(@options)
        @prod_stack = []

        @formulae = []
        @formula_nodes = {}
        @label_uniquifier = "0"
        @bnodes = {}
        @bn_labler = @options[:anon_base].dup
        @bn_mapper = {}
        @variables = {}

        if options[:base_uri]
          progress("base_uri") { base_uri.inspect}
          namespace(nil, iri(base_uri.to_s.match?(%r{[#/]$}) ? base_uri : "#{base_uri}#"))
        end

        # Prepopulate operator namespaces unless validating
        unless validate?
          namespace(:rdf, RDF.to_uri)
          namespace(:rdfs, RDF::RDFS.to_uri)
          namespace(:xsd, RDF::XSD.to_uri)
          namespace(:crypto, RDF::N3::Crypto.to_uri)
          namespace(:list, RDF::N3::List.to_uri)
          namespace(:log, RDF::N3::Log.to_uri)
          namespace(:math, RDF::N3::Math.to_uri)
          namespace(:rei, RDF::N3::Rei.to_uri)
          #namespace(:string, RDF::N3::String.to_uri)
          namespace(:time, RDF::N3::Time.to_uri)
        end
        progress("validate") {validate?.inspect}
        progress("canonicalize") {canonicalize?.inspect}

        @lexer = EBNF::LL1::Lexer.new(input, self.class.patterns, **@options)

        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, base_uri.to_s)
    end

    ##
    # Iterates the given block for each RDF statement in the input.
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        log_recover
        @callback = block

        begin
          while (@lexer.first rescue true)
            read_n3Doc
          end
        rescue EBNF::LL1::Lexer::Error, SyntaxError, EOFError, Recovery
          # Terminate loop if EOF found while recovering
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
    def each_triple
      if block_given?
        each_statement do |statement|
          yield(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end

    protected

    # Terminals passed to lexer. Order matters!

    # @!parse none
    terminal(:ANON,                             ANON)
    terminal(:BLANK_NODE_LABEL,                 BLANK_NODE_LABEL)
    terminal(:IRIREF,                           IRIREF, unescape:  true)
    terminal(:DOUBLE,                           DOUBLE)
    terminal(:DECIMAL,                          DECIMAL)
    terminal(:INTEGER,                          INTEGER)
    terminal(:PNAME_LN,                         PNAME_LN, unescape:  true)
    terminal(:PNAME_NS,                         PNAME_NS)
    terminal(:STRING_LITERAL_LONG_SINGLE_QUOTE, STRING_LITERAL_LONG_SINGLE_QUOTE, unescape:  true, partial_regexp: /^'''/)
    terminal(:STRING_LITERAL_LONG_QUOTE,        STRING_LITERAL_LONG_QUOTE,        unescape:  true, partial_regexp: /^"""/)
    terminal(:STRING_LITERAL_QUOTE,             STRING_LITERAL_QUOTE,             unescape:  true)
    terminal(:STRING_LITERAL_SINGLE_QUOTE,      STRING_LITERAL_SINGLE_QUOTE,      unescape:  true)

    # String terminals
    terminal(nil,                               %r(
                                                   [\(\){},.;\[\]a!]
                                                 | \^\^|\^
                                                 |<-|<=|=>|=
                                                 | true|false
                                                 | has|is|of
                                                )x)

    terminal(:PREFIX,                           PREFIX)
    terminal(:BASE,                             BASE)
    terminal(:LANGTAG,                          LANGTAG)
    terminal(:QUICK_VAR_NAME,                   QUICK_VAR_NAME,                  unescape:  true)

  private
    ##
    # Read statements and directives
    #
    #      [1]  n3Doc ::= (n3Statement '.' | sparqlDirective)*
    #
    # @return [void]
    def read_n3Doc
      prod(:n3Doc, %w{.}) do
        error("read_n3Doc", "Unexpected end of file") unless token = @lexer.first
        case token.type
        when :BASE, :PREFIX
          read_directive || error("Failed to parse directive", production: :directive, token: token)
        else
          read_n3Statement
          if !log_recovering? || @lexer.first === '.'
            # If recovering, we will have eaten the closing '.'
            token = @lexer.shift
            unless token && token.value == '.'
              error("Expected '.' following n3Statement", production: :n3Statement, token: token)
            end
          end
        end
      end
    end


    ##
    # Read statements and directives
    #
    #     [2]  n3Statement ::= n3Directive | triples | existential | universal
    #
    # @return [void]
    def read_n3Statement
      prod(:n3Statement, %w{.}) do
        error("read_n3Doc", "Unexpected end of file") unless token = @lexer.first
        read_triples ||
        error("Expected token", production: :statement, token: token)
      end
    end

    ##
    # Read base and prefix directives
    #
    #     [3]  n3Directive ::= prefixID | base
    #
    # @return [void]
    def read_directive
      prod(:directive, %w{.}) do
        token = @lexer.first
        case token.type
        when :BASE
          prod(:base) do
            @lexer.shift
            terminated = token.value == '@base'
            iri = @lexer.shift
            error("Expected IRIREF", production: :base, token: iri) unless iri === :IRIREF
            @options[:base_uri] = process_iri(iri.value[1..-2].gsub(/\s/, ''))
            namespace(nil, base_uri.to_s.end_with?('#') ? base_uri : iri("#{base_uri}#"))
            error("base", "#{token} should be downcased") if token.value.start_with?('@') && token.value != '@base'

            if terminated
              error("base", "Expected #{token} to be terminated") unless @lexer.first === '.'
              @lexer.shift
            elsif @lexer.first === '.'
              error("base", "Expected #{token} not to be terminated") 
            else
              true
            end
          end
        when :PREFIX
          prod(:prefixID, %w{.}) do
            @lexer.shift
            pfx, iri = @lexer.shift, @lexer.shift
            terminated = token.value == '@prefix'
            error("Expected PNAME_NS", production: :prefix, token: pfx) unless pfx === :PNAME_NS
            error("Expected IRIREF", production: :prefix, token: iri) unless iri === :IRIREF
            debug("prefixID", depth: options[:depth]) {"Defined prefix #{pfx.inspect} mapping to #{iri.inspect}"}
            namespace(pfx.value[0..-2], process_iri(iri.value[1..-2].gsub(/\s/, '')))
            error("prefixId", "#{token} should be downcased") if token.value.start_with?('@') && token.value != '@prefix'

            if terminated
              error("prefixID", "Expected #{token} to be terminated") unless @lexer.first === '.'
              @lexer.shift
            elsif @lexer.first === '.'
              error("prefixID", "Expected #{token} not to be terminated") 
            else
              true
            end
          end
        end
      end
    end

    ##
    # Read triples
    #
    #     [9]  triples ::= subject predicateObjectList?
    #
    # @return [Object] returns the last IRI matched, or subject BNode on predicateObjectList?
    def read_triples
      prod(:triples, %w{.}) do
        error("read_triples", "Unexpected end of file") unless token = @lexer.first
        subject = case token.type || token.value
        when '['
          # blankNodePropertyList predicateObjectList? 
          read_blankNodePropertyList || error("Failed to parse blankNodePropertyList", production: :triples, token: @lexer.first)
        else
          # subject predicateObjectList
          read_path || error("Failed to parse subject", production: :triples, token: @lexer.first)
        end
        read_predicateObjectList(subject) || subject
      end
    end

    ##
    # Read predicateObjectList
    #
    #     [10] predicateObjectList ::= verb objectList (';' (verb objectList)?)*
    #
    # @param [RDF::Resource] subject
    # @return [RDF::URI] the last matched verb
    def read_predicateObjectList(subject)
      return if @lexer.first.nil? || %w(. }).include?(@lexer.first.value)
      prod(:predicateObjectList, %{;}) do
        last_verb = nil
        loop do
          verb, invert = read_verb
          break unless verb
          last_verb = verb
          prod(:_predicateObjectList_2) do
            read_objectList(subject, verb, invert) || error("Expected objectList", production: :predicateObjectList, token: @lexer.first)
          end
          break unless @lexer.first === ';'
          @lexer.shift while @lexer.first === ';'
        end
        last_verb
      end
    end

    ##
    # Read objectList
    #
    #     [11] objectList ::= object (',' object)*
    #
    # @return [RDF::Term] the last matched subject
    def read_objectList(subject, predicate, invert)
      prod(:objectList, %{,}) do
        last_object = nil
        while object = prod(:_objectList_2) {read_path}
          last_object = object

          if invert
             add_statement(:objectList, object, predicate, subject)
          else
            add_statement(:objectList, subject, predicate, object)
          end

          break unless @lexer.first === ','
          @lexer.shift while @lexer.first === ','
        end
        last_object
      end
    end

    ##
    # Read a verb
    #
    #     [12] verb = predicate
    #               | 'a'
    #               | 'has' expression
    #               | 'is' expression 'of'
    #               | '<-' expression
    #               | '<='
    #               | '=>'
    #               | '='
    #     
    # @return [RDF::Resource, Boolean] verb and invert?
    def read_verb
      invert = false
      error("read_verb", "Unexpected end of file") unless token = @lexer.first
      verb = case token.type || token.value
      when 'a' then prod(:verb) {@lexer.shift && RDF.type}
      when 'has' then prod(:verb) {@lexer.shift && read_path}
      when 'is' then prod(:verb) {
        @lexer.shift
        invert, v = true, read_path
        error( "Expected 'of'", production: :verb, token: @lexer.first) unless @lexer.first.value == 'of'
        @lexer.shift
        v
      }
      when '<-' then prod(:verb) {
        @lexer.shift
        invert = true
        read_path
      }
      when '<=' then prod(:verb) {
        @lexer.shift
        invert = true
        RDF::N3::Log.implies
      }
      when '=>' then prod(:verb) {@lexer.shift && RDF::N3::Log.implies}
      when '='  then prod(:verb) {@lexer.shift && RDF::OWL.sameAs}
      else read_path
      end
      [verb, invert]
    end

    ##
    # subjects, predicates and objects are all expressions, which are all paths
    #
    #     [13] subject       ::= expression
    #     [14] predicate     ::= expression
    #     [16] expression    ::= path
    #     [17] path	         ::= pathItem ('!' path | '^' path)?
    #
    # @return [RDF::Resource]
    def read_path
      return if @lexer.first.nil? || %w/. } ) ]/.include?(@lexer.first.value)
      prod(:path) do
        pathtail = path = {}
        loop do
          pathtail[:pathitem] = prod(:pathItem) do
            read_iri ||
            read_blankNode ||
            read_quickVar ||
            read_collection ||
            read_blankNodePropertyList ||
            read_literal ||
            read_formula
          end

          break if @lexer.first.nil? || !%w(! ^).include?(@lexer.first.value)
          prod(:_path_2) do
            pathtail[:direction] = @lexer.shift.value == '!' ? :forward : :reverse
            pathtail = pathtail[:pathtail] = {}
          end
        end

        # Returns the first object in the path
        # FIXME: what if it's a verb?
        process_path(path)
      end
    end

    ##
    # Read a literal
    #
    #     [19] literal ::= rdfLiteral | numericLiteral | BOOLEAN_LITERAL
    #
    # @return [RDF::Literal]
    def read_literal
      error("Unexpected end of file", production: :literal) unless token = @lexer.first
      case token.type || token.value
      when :INTEGER then prod(:literal) {literal(@lexer.shift.value, datatype:  RDF::XSD.integer, canonicalize: canonicalize?)}
      when :DECIMAL
        prod(:literal) do
          value = @lexer.shift.value
          value = "0#{value}" if value.start_with?(".")
          literal(value, datatype:  RDF::XSD.decimal, canonicalize: canonicalize?)
        end
      when :DOUBLE then prod(:literal) {literal(@lexer.shift.value.sub(/\.([eE])/, '.0\1'), datatype:  RDF::XSD.double, canonicalize: canonicalize?)}
      when "true", "false" then prod(:literal) {literal(@lexer.shift.value, datatype: RDF::XSD.boolean, canonicalize: canonicalize?)}
      when :STRING_LITERAL_QUOTE, :STRING_LITERAL_SINGLE_QUOTE
        prod(:literal) do
          value = @lexer.shift.value[1..-2]
          error("read_literal", "Unexpected end of file") unless token = @lexer.first
          case token.type || token.value
          when :LANGTAG
            literal(value, language: @lexer.shift.value[1..-1].to_sym)
          when '^^'
            @lexer.shift
            literal(value, datatype: read_iri)
          else
            literal(value)
          end
        end
      when :STRING_LITERAL_LONG_QUOTE, :STRING_LITERAL_LONG_SINGLE_QUOTE
        prod(:literal) do
          value = @lexer.shift.value[3..-4]
          error("read_literal", "Unexpected end of file") unless token = @lexer.first
          case token.type || token.value
          when :LANGTAG
            literal(value, language: @lexer.shift.value[1..-1].to_sym)
          when '^^'
            @lexer.shift
            literal(value, datatype: read_iri)
          else
            literal(value)
          end
        end
      end
    end

    ##
    # Read a blankNodePropertyList
    #
    #     [20] blankNodePropertyList ::= '[' predicateObjectList ']'
    #
    # @return [RDF::Node]
    def read_blankNodePropertyList
      token = @lexer.first
      if token === '['
        prod(:blankNodePropertyList, %{]}) do
          @lexer.shift
          progress("blankNodePropertyList", depth: options[:depth], token: token)
          node = bnode
          debug("blankNodePropertyList: subject", depth: options[:depth]) {node.to_sxp}
          read_predicateObjectList(node)
          error("blankNodePropertyList", "Expected closing ']'") unless @lexer.first === ']'
          @lexer.shift
          node
        end
      end
    end

    ##
    # Read a collection (`RDF::List`)
    #
    #     [21] collection ::= '(' object* ')'
    #
    # If the `list_terms` option is given, the resulting resource is a list, otherwise, it is the list subject, and the first/rest entries are also emitted.
    # @return [RDF::Node]
    def read_collection
      if @lexer.first === '('
        prod(:collection, %{)}) do
          @lexer.shift
          token = @lexer.first
          progress("collection", depth: options[:depth]) {"token: #{token.inspect}"}
          objects = []
          while @lexer.first.value != ')' && (object = read_path)
            objects << object
          end
          error("collection", "Expected closing ')'") unless @lexer.first === ')'
          @lexer.shift
          list = RDF::N3::List.new(values: objects)
          if options[:list_terms]
            list
          else
            list.each_statement do |statement|
              add_statement("collection", *statement.to_a)
            end
            list.subject
          end
        end
      end
    end

    ##
    # Read a formula
    #
    #     [22] formula         ::= '{' formulaContent? '}'
    #     [23] formulaContent  ::= n3Statement ('.' formulaContent?)?
    #
    # @return [RDF::Node]
    def read_formula
      if @lexer.first === '{'
        prod(:formula, %(})) do
          @lexer.shift
          node = RDF::Node.intern("_form_#{unique_label}")
          formulae.push(node)
          formula_nodes[node] = true
          debug(:formula, depth: @options[:depth]) {"id: #{node}, depth: #{formulae.length}"}

          read_formulaContent

          # Pop off the formula
          # Result is the BNode associated with the formula
          debug(:formula, depth: @options[:depth]) {"pop: #{formulae.last}, depth: #{formulae.length}"}
          error("collection", "Expected closing '}'") unless @lexer.shift === '}'

          formulae.pop
        end
      end
    end

    ##
    # Read formula content, similaer to n3Statement
    #
    #     [23] formulaContent  ::= n3Statement ('.' formulaContent?)?
    #
    # @return [void]
    def read_formulaContent
      return if @lexer.first === '}'  # Allow empty formula
      prod(:formulaContent, %w(. })) do
        loop do
          token = @lexer.first
          error("read_formulaContent", "Unexpected end of file") unless token
          case token.type
          when :BASE, :PREFIX
            read_directive || error("Failed to parse directive", production: :directive, token: token)
            break if @lexer.first === '}'
          else
            read_n3Statement
            token = @lexer.first
            case token.value
            when '.'
              @lexer.shift
              # '.' optional at end of formulaContent
              break if @lexer.first === '}'
            when '}'
              break
            else
              error("Expected '.' or '}' following n3Statement", production: :formulaContent, token: token)
            end
          end
        end
      end
    end

    ##
    # Read an IRI
    #
    #     (rule iri "26" (alt IRIREF prefixedName))
    #
    # @return [RDF::URI]
    def read_iri
      token = @lexer.first
      case token && token.type
      when :IRIREF then prod(:iri)  {process_iri(@lexer.shift.value[1..-2].gsub(/\s+/m, ''))}
      when :PNAME_LN, :PNAME_NS then prod(:prefixedName) {process_pname(*@lexer.shift.value)}
      end
    end

    ##
    # Read a blank node
    #
    #     [29] blankNode ::=  BLANK_NODE_LABEL | ANON
    #
    # @return [RDF::Node]
    def read_blankNode
      token = @lexer.first
      case token && token.type
      when :BLANK_NODE_LABEL then prod(:blankNode) {bnode(@lexer.shift.value[2..-1])}
      when :ANON then @lexer.shift && prod(:blankNode) {bnode}
      end
    end

    ##
    # Read a quickVar, having global scope.
    #
    #     [30] quickVar ::= QUICK_VAR_NAME
    #
    # @return [RDF::Query::Variable]
    def read_quickVar
      if @lexer.first.type == :QUICK_VAR_NAME
        prod(:quickVar) do
          token = @lexer.shift
          value = token.value.sub('?', '')
          variables[value] ||= RDF::Query::Variable.new(value)
        end
      end
    end

    ###################
    # Utility Functions
    ###################

    # Process a path, such as:
    #   :a!:b means [is :b of :a] => :a :b []
    #   :a^:b means [:b :a]       => [] :b :a
    #
    # Create triple and return property used for next iteration
    #
    # Result is last created bnode
    def process_path(path)
      pathitem, direction, pathtail = path[:pathitem], path[:direction], path[:pathtail]
      debug("process_path", depth: @options[:depth]) {path.inspect}

      while pathtail
        bnode = bnode()
        pred = pathtail.is_a?(RDF::Term) ? pathtail : pathtail[:pathitem]
        if direction == :reverse
          add_statement("process_path(reverse)", bnode, pred, pathitem)
        else
          add_statement("process_path(forward)", pathitem, pred, bnode)
        end
        pathitem = bnode
        direction = pathtail[:direction] if pathtail.is_a?(Hash)
        pathtail = pathtail.is_a?(Hash) && pathtail[:pathtail]
      end
      pathitem
    end

    def process_iri(iri)
      iri(base_uri, iri.to_s)
    end

    def process_pname(value)
      prefix, name = value.split(":", 2)

      iri = if prefix(prefix)
        #debug('process_pname(ns)', depth: @options[:depth]) {"#{prefix(prefix)}, #{name}"}
        ns(prefix, name)
      elsif prefix && !prefix.empty?
        error("process_pname", "Use of undefined prefix #{prefix.inspect}")
        ns(nil, name)
      else
        ns(nil, name)
      end
      debug('process_pname', depth: @options[:depth]) {iri.inspect}
      iri
    end

    # Keep track of allocated BNodes. Blank nodes are allocated to the formula.
    # Unnnamed bnodes are created using an incrementing labeler for repeatability.
    def bnode(label = nil)
      form_id = formulae.last ? formulae.last.id : '_bn_ground'
      if label
        # Return previously allocated blank node for.
        @bn_mapper[form_id] ||= {}
        return @bn_mapper[form_id][label] if @bn_mapper[form_id][label]
      end

      # Get a fresh label
      @bn_labler.succ! while @bnodes[@bn_labler]

      bn = RDF::Node.intern(@bn_labler.to_sym)
      @bnodes[@bn_labler] = bn
      @bn_mapper[form_id][label] = bn if label
      bn
    end

    # If not in ground formula, note scope, and if existential
    def univar(label, scope:)
      value = label
      RDF::Query::Variable.new(value)
    end

    # add a pattern or statement
    #
    # @param [any] node string for showing graph_name
    # @param [RDF::Term] subject the subject of the statement
    # @param [RDF::URI] predicate the predicate of the statement
    # @param [RDF::Term] object the object of the statement
    # @return [Statement] Added statement
    # @raise [RDF::ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_statement(node, subject, predicate, object)
      statement = if @formulae.last
        # It's a pattern in a formula
        RDF::Query::Pattern.new(subject, predicate, object, graph_name: @formulae.last)
      else
        RDF::Statement(subject, predicate, object)
      end
      debug("statement(#{node})", depth: @options[:depth]) {statement.to_s}
      error("statement(#{node})", "Statement is invalid: #{statement.inspect}") if validate? && statement.invalid?
      @callback.call(statement)
    end

    def namespace(prefix, iri)
      iri = iri.to_s
      if iri == '#'
        iri = prefix(nil).to_s + '#'
      end
      debug("namespace", depth: @options[:depth]) {"'#{prefix}' <#{iri}>"}
      prefix(prefix, iri(iri))
    end

    # Create IRIs
    def iri(value, append = nil)
      value = RDF::URI(value)
      value = value.join(append) if append
      value.validate! if validate? && value.respond_to?(:validate)
      value.canonicalize! if canonicalize?

      # Variable substitution for in-scope variables. Variables are in scope if they are defined in anthing other than the current formula
      var = find_var(value)
      value = var if var

      value
    rescue ArgumentError => e
      error("iri", e.message)
    end
    
    # Create a literal
    def literal(value, **options)
      debug("literal", depth: @options[:depth]) do
        "value: #{value.inspect}, " +
        "options: #{options.inspect}, " +
        "validate: #{validate?.inspect}, " +
        "c14n?: #{canonicalize?.inspect}"
      end
      RDF::Literal.new(value, validate:  validate?, canonicalize: canonicalize?, **options)
    rescue ArgumentError => e
      error("Argument Error #{e.message}", production: :literal, token: @lexer.first)
    end

    # Decode a PName
    def ns(prefix = nil, suffix = nil)
      namespace(nil, iri("#{base_uri}#")) if prefix.nil? && !prefix(nil)

      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      iri(base + suffix.to_s)
    end

    # Returns a unique label
    def unique_label
      label, @label_uniquifier = @label_uniquifier, @label_uniquifier.succ
      label
    end

    # Find any variable that may be defined identified by `name`
    # @param [RDF::Node] name of formula
    # @return [RDF::Query::Variable]
    def find_var(name)
      variables[name.to_s]
    end

    def prod(production, recover_to = [])
      @prod_stack << {prod: production, recover_to: recover_to}
      @options[:depth] += 1
      recover("#{production}(start)", depth: options[:depth], token: @lexer.first)
      yield
    rescue EBNF::LL1::Lexer::Error, SyntaxError, Recovery =>  e
      # Lexer encountered an illegal token or the parser encountered
      # a terminal which is inappropriate for the current production.
      # Perform error recovery to find a reasonable terminal based
      # on the follow sets of the relevant productions. This includes
      # remaining terms from the current production and the stacked
      # productions
      case e
      when EBNF::LL1::Lexer::Error
        @lexer.recover
        begin
          error("Lexer error", "With input '#{e.input}': #{e.message}",
            production: production,
            token: e.token)
        rescue SyntaxError
        end
      end
      raise EOFError, "End of input found when recovering" if @lexer.first.nil?
      debug("recovery", "current token: #{@lexer.first.inspect}", depth: @options[:depth])

      unless e.is_a?(Recovery)
        # Get the list of follows for this sequence, this production and the stacked productions.
        debug("recovery", "stack follows:", depth: @options[:depth])
        @prod_stack.reverse.each do |prod|
          debug("recovery", level: 1, depth: @options[:depth]) {"  #{prod[:prod]}: #{prod[:recover_to].inspect}"}
        end
      end

      # Find all follows to the top of the stack
      follows = @prod_stack.map {|prod| Array(prod[:recover_to])}.flatten.compact.uniq

      # Skip tokens until one is found in follows
      while (token = (@lexer.first rescue @lexer.recover)) && follows.none? {|t| token === t}
        skipped = @lexer.shift
        debug("recovery", depth: @options[:depth]) {"skip #{skipped.inspect}"}
      end
      debug("recovery", depth: @options[:depth]) {"found #{token.inspect} in follows"}

      # Re-raise the error unless token is a follows of this production
      raise Recovery unless Array(recover_to).any? {|t| token === t}

      # Skip that token to get something reasonable to start the next production with
      @lexer.shift
    ensure
      progress("#{production}(finish)", depth: options[:depth])
      @options[:depth] -= 1
      @prod_stack.pop
    end

    def progress(*args, &block)
      lineno = (options[:token].lineno if options[:token].respond_to?(:lineno)) || (@lexer && @lexer.lineno)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:level] ||= 1
      opts[:lineno] ||= lineno
      log_info(*args, **opts, &block)
    end

    def recover(*args, &block)
      lineno = (options[:token].lineno if options[:token].respond_to?(:lineno)) || (@lexer && @lexer.lineno)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:level] ||= 1
      opts[:lineno] ||= lineno
      log_recover(*args, **opts, &block)
    end

    def debug(*args, &block)
      lineno = (options[:token].lineno if options[:token].respond_to?(:lineno)) || (@lexer && @lexer.lineno)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:level] ||= 0
      opts[:lineno] ||= lineno
      log_debug(*args, **opts, &block)
    end

    ##
    # Error information, used as level `0` debug messages.
    #
    # @overload error(node, message, options)
    #   @param [String] node Relevant location associated with message
    #   @param [String] message Error string
    #   @param [Hash] options
    #   @option options [URI, #to_s] :production
    #   @option options [Token] :token
    #   @see {#debug}
    def error(*args)
      ctx = ""
      ctx += "(found #{options[:token].inspect})" if options[:token]
      ctx += ", production = #{options[:production].inspect}" if options[:production]
      lineno = (options[:token].lineno if options[:token].respond_to?(:lineno)) || (@lexer && @lexer.lineno)
      log_error(*args, ctx,
        lineno:     lineno,
        token:      options[:token],
        production: options[:production],
        depth:      options[:depth],
        exception:  SyntaxError,)
    end

    # Used for internal error recovery
    class Recovery < StandardError; end

    class SyntaxError < RDF::ReaderError
      ##
      # The current production.
      #
      # @return [Symbol]
      attr_reader :production

      ##
      # The invalid token which triggered the error.
      #
      # @return [String]
      attr_reader :token

      ##
      # The line number where the error occurred.
      #
      # @return [Integer]
      attr_reader :lineno

      ##
      # Initializes a new syntax error instance.
      #
      # @param  [String, #to_s]          message
      # @param  [Hash{Symbol => Object}] options
      # @option options [Symbol]         :production  (nil)
      # @option options [String]         :token  (nil)
      # @option options [Integer]        :lineno (nil)
      def initialize(message, **options)
        @production = options[:production]
        @token      = options[:token]
        @lineno     = options[:lineno] || (@token.lineno if @token.respond_to?(:lineno))
        super(message.to_s)
      end
    end
  end
end
