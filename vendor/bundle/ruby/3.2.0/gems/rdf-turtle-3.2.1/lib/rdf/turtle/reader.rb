# coding: utf-8
require 'ebnf/ll1/lexer'

module RDF::Turtle
  ##
  # A parser for the Turtle 2
  class Reader < RDF::Reader
    format Format
    include EBNF::LL1::Parser
    include RDF::Turtle::Terminals
    include RDF::Util::Logger

    # Terminals passed to lexer. Order matters!
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
                                                    [\(\),.;\[\]Aa]
                                                  | \^\^
                                                  | \{\|
                                                  | \|\}
                                                  | true|false
                                                  | <<|>>
                                                )x)

    terminal(:PREFIX,                           PREFIX)
    terminal(:BASE,                             BASE)
    terminal(:LANGTAG,                          LANGTAG)

    ##
    # Reader options
    # @see https://ruby-rdf.github.io/rdf/RDF/Reader#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :freebase,
          datatype: TrueClass,
          on: ["--freebase"],
          description: "Use optimized Freebase reader.") {true},
      ]
    end

    ##
    # Redirect for Freebase Reader
    #
    # @private
    def self.new(input = nil, **options, &block)
      klass = if options[:freebase]
        FreebaseReader
      else
        self
      end
      reader = klass.allocate
      reader.send(:initialize, input, **options, &block)
      reader
    end

    ##
    # Initializes a new reader instance.
    #
    # Note, the spec does not define a default mapping for the empty prefix,
    # but it is so commonly used in examples that we define it to be the
    # empty string anyway, except when validating.
    #
    # @param  [String, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (for acessing intermediate parser productions)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @option options [#to_s]    :anon_base     ("b0")
    #   Basis for generating anonymous Nodes
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values. If not validating,
    #   the parser will attempt to recover from errors.
    # @option options [Logger, #write, #<<] :logger
    #   Record error/info/debug output
    # @option options [Boolean] :freebase (false)
    #   Use optimized Freebase reader
    # @return [RDF::Turtle::Reader]
    def initialize(input = nil, **options, &block)
      super do
        @options = {
          anon_base:  "b0",
          whitespace:  WS,
          depth: 0,
        }.merge(@options)
        @prod_stack = []

        @options[:base_uri] = RDF::URI(base_uri || "")
        debug("base IRI") {base_uri.inspect}
        
        debug("validate") {validate?.inspect}
        debug("canonicalize") {canonicalize?.inspect}
        debug("intern") {intern?.inspect}

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
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        log_recover
        @callback = block

        begin
          while (@lexer.first rescue true)
            read_statement
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
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end

    # add a statement, object can be literal or URI or bnode
    #
    # @param [Symbol] production
    # @param [RDF::Statement] statement the subject of the statement
    # @return [RDF::Statement] Added statement
    # @raise [RDF::ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_statement(production, statement)
      error("Statement is invalid: #{statement.inspect}", production: produciton) if validate? && statement.invalid?
      @callback.call(statement) if statement.subject &&
                                   statement.predicate &&
                                   statement.object &&
                                   (validate? ? statement.valid? : true)
    end

    # Process a URI against base
    def process_iri(iri)
      iri = iri.value[1..-2] if iri === :IRIREF
      value = RDF::URI(iri)
      value = base_uri.join(value) if value.relative?
      value.validate! if validate?
      value.canonicalize! if canonicalize? && !value.frozen?
      value = RDF::URI.intern(value) if intern?
      value
    rescue ArgumentError => e
      error("process_iri", e)
    end
    
    # Create a literal
    def literal(value, **options)
      debug("literal", depth: @options[:depth]) do
        "value: #{value.inspect}, " +
        "options: #{options.inspect}, " +
        "validate: #{validate?.inspect}, " +
        "c14n?: #{canonicalize?.inspect}"
      end
      RDF::Literal.new(value, validate:  validate?, canonicalize:  canonicalize?, **options)
    rescue ArgumentError => e
      error("Argument Error #{e.message}", production: :literal, token: @lexer.first)
    end

    ##
    # Override #prefix to take a relative IRI
    #
    # prefix directives map a local name to an IRI, also resolved against the current In-Scope Base URI.
    # Spec confusion, presume that an undefined empty prefix has an empty relative IRI, which uses
    # string contatnation rules against the in-scope IRI at the time of use
    def prefix(prefix, iri = nil)
      # Relative IRIs are resolved against @base
      iri = process_iri(iri) if iri
      super(prefix, iri)
    end
    
    ##
    # Expand a PNAME using string concatenation
    def pname(prefix, suffix)
      # Prefixes must be defined, except special case for empty prefix being alias for current @base
      base = if prefix(prefix)
        prefix(prefix).to_s
      elsif prefix.to_s.empty? && !validate?
        base_uri.to_s
      else
        error("undefined prefix", production: :pname, token: prefix)
        ''
      end
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug("pname", depth: options[:depth]) {"base: '#{base}', suffix: '#{suffix}'"}
      process_iri(base + suffix.to_s)
    end
    
    # Keep track of allocated BNodes
    def bnode(value = nil)
      return RDF::Node.new unless value
      @bnode_cache ||= {}
      @bnode_cache[value.to_s] ||= RDF::Node.new(value)
    end

  protected
    # @return [void]
    def read_statement
      prod(:statement, %w{.}) do
        error("read_statement", "Unexpected end of file") unless token = @lexer.first
        case token.type
        when :BASE, :PREFIX
          read_directive || error("Failed to parse directive", production: :directive, token: token)
        else
          read_triples || error("Expected token", production: :statement, token: token)
          if !log_recovering? || @lexer.first === '.'
            # If recovering, we will have eaten the closing '.'
            token = @lexer.shift
            unless token && token.value == '.'
              error("Expected '.' following triple", production: :statement, token: token)
            end
          end
        end
      end
    end

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
            @options[:base_uri] = process_iri(iri)
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
            prefix(pfx.value[0..-2], process_iri(iri))
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

    # @return [Object] returns the last verb matched, or subject BNode on predicateObjectList?
    def read_triples
      prod(:triples, %w{.}) do
        error("read_triples", "Unexpected end of file") unless token = @lexer.first
        case token.type || token.value
        when '['
          # blankNodePropertyList predicateObjectList? 
          subject = read_blankNodePropertyList || error("Failed to parse blankNodePropertyList", production: :triples, token: @lexer.first)
          read_predicateObjectList(subject) || subject
        else
          # subject predicateObjectList
          subject = read_subject || error("Failed to parse subject", production: :triples, token: @lexer.first)
          read_predicateObjectList(subject) || error("Expected predicateObjectList", production: :triples, token: @lexer.first)
        end
      end
    end

    # @param [RDF::Resource] subject
    # @return [RDF::URI] the last matched verb
    def read_predicateObjectList(subject)
      prod(:predicateObjectList, %{;}) do
        last_verb = nil
        while verb = read_verb
          last_verb = verb
          prod(:_predicateObjectList_5) do
            read_objectList(subject, verb) || error("Expected objectList", production: :predicateObjectList, token: @lexer.first)
          end
          break unless @lexer.first === ';'
          @lexer.shift while @lexer.first === ';'
        end
        last_verb
      end
    end

    # @return [RDF::Term] the last matched subject
    def read_objectList(subject, predicate)
      prod(:objectList, %{,}) do
        last_object = nil
        while object = prod(:_objectList_2) {read_object(subject, predicate)}
          last_object = object

          # If object is followed by an annotation, read that and also emit an embedded triple.
          read_annotation(subject, predicate, object)

          break unless @lexer.first === ','
          @lexer.shift while @lexer.first === ','
        end
        last_object
      end
    end

    # @return [RDF::URI]
    def read_verb
      error("read_verb", "Unexpected end of file") unless token = @lexer.first
      case token.type || token.value
      when 'a' then prod(:verb) {@lexer.shift && RDF.type}
      else prod(:verb) {read_iri}
      end
    end

    # @return [RDF::Resource]
    def read_subject
      prod(:subject) do
        read_iri ||
        read_BlankNode ||
        read_collection ||
        read_quotedTriple ||
        error( "Expected subject", production: :subject, token: @lexer.first)
      end
    end

    # @return [void]
    def read_object(subject = nil, predicate = nil)
      prod(:object) do
        if object = read_iri ||
          read_BlankNode ||
          read_collection ||
          read_blankNodePropertyList ||
          read_literal ||
          read_quotedTriple

          add_statement(:object, RDF::Statement(subject, predicate, object)) if subject && predicate
          object
        end
      end
    end

    # Read an RDF-star reified statement
    # @return [RDF::Statement]
    def read_quotedTriple
      return unless @options[:rdfstar]
      if @lexer.first.value == '<<'
        prod(:quotedTriple) do
          @lexer.shift # eat <<
          subject = read_qtSubject || error("Failed to parse subject", production: :quotedTriple, token: @lexer.first)
          predicate = read_verb || error("Failed to parse predicate", production: :quotedTriple, token: @lexer.first)
          object = read_qtObject || error("Failed to parse object", production: :quotedTriple, token: @lexer.first)
          unless @lexer.first.value == '>>'
            error("Failed to end of embedded triple", production: :quotedTriple, token: @lexer.first)
          end
          @lexer.shift
          statement = RDF::Statement(subject, predicate, object, quoted: true)
          statement
        end
      end
    end

    # @return [RDF::Resource]
    def read_qtSubject
      prod(:qtSubject) do
        read_iri ||
        read_BlankNode ||
        read_quotedTriple ||
        error( "Expected embedded subject", production: :qtSubject, token: @lexer.first)
      end
    end

    # @return [RDF::Term]
    def read_qtObject(subject = nil, predicate = nil)
      prod(:qtObject) do
        read_iri ||
        read_BlankNode ||
        read_literal ||
        read_quotedTriple
      end
    end

    # Read an annotation on a triple
    def read_annotation(subject, predicate, object)
      error("Unexpected end of file", production: :annotation) unless token = @lexer.first
      if token === '{|'
        prod(:annotation, %(|})) do
          @lexer.shift

          # Statement becomes subject for predicateObjectList
          statement = RDF::Statement(subject, predicate, object, quoted: true)
          read_predicateObjectList(statement) ||
            error("Expected predicateObjectList", production: :annotation, token: @lexer.first)
          error("annotation", "Expected closing '|}'") unless @lexer.first === '|}'
          @lexer.shift
        end
      end

    end

    # @return [RDF::Literal]
    def read_literal
      error("Unexpected end of file", production: :literal) unless token = @lexer.first
      case token.type || token.value
      when :INTEGER then prod(:literal) {literal(@lexer.shift.value, datatype:  RDF::XSD.integer)}
      when :DECIMAL
        prod(:literal) do
          value = @lexer.shift.value
          value = "0#{value}" if value.start_with?(".")
          literal(value, datatype:  RDF::XSD.decimal)
        end
      when :DOUBLE then prod(:literal) {literal(@lexer.shift.value.sub(/\.([eE])/, '.0\1'), datatype:  RDF::XSD.double)}
      when "true", "false" then prod(:literal) {literal(@lexer.shift.value, datatype: RDF::XSD.boolean)}
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

    # @return [RDF::Node]
    def read_blankNodePropertyList
      token = @lexer.first
      if token === '['
        prod(:blankNodePropertyList, %{]}) do
          @lexer.shift
          progress("blankNodePropertyList", depth: options[:depth]) {"token: #{token.inspect}"}
          node = bnode
          read_predicateObjectList(node)
          error("blankNodePropertyList", "Expected closing ']'") unless @lexer.first === ']'
          @lexer.shift
          node
        end
      end
    end

    # @return [RDF::Node]
    def read_collection
      if @lexer.first === '('
        prod(:collection, %{)}) do
          @lexer.shift
          token = @lexer.first
          progress("collection", depth: options[:depth]) {"token: #{token.inspect}"}
          objects = []
          while object = read_object
            objects << object
          end
          list = RDF::List.new(values: objects)
          list.each_statement do |statement|
            add_statement("collection", statement)
          end
          error("collection", "Expected closing ')'") unless @lexer.first === ')'
          @lexer.shift
          list.subject
        end
      end
    end

    # @return [RDF::URI]
    def read_iri
      token = @lexer.first
      case token && token.type
      when :IRIREF then prod(:iri)  {process_iri(@lexer.shift)}
      when :PNAME_LN, :PNAME_NS then prod(:iri) {pname(*@lexer.shift.value.split(':', 2))}
      end
    end

    # @return [RDF::Node]
    def read_BlankNode
      token = @lexer.first
      case token && token.type
      when :BLANK_NODE_LABEL then prod(:BlankNode) {bnode(@lexer.shift.value[2..-1])}
      when :ANON then @lexer.shift && prod(:BlankNode) {bnode}
      end
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
      debug("recovery", "current token: #{@lexer.first.inspect}", depth: options[:depth])

      unless e.is_a?(Recovery)
        # Get the list of follows for this sequence, this production and the stacked productions.
        debug("recovery", "stack follows:", depth: options[:depth])
        @prod_stack.reverse.each do |prod|
          debug("recovery", level: 4, depth: options[:depth]) {"  #{prod[:prod]}: #{prod[:recover_to].inspect}"}
        end
      end

      # Find all follows to the top of the stack
      follows = @prod_stack.map {|prod| Array(prod[:recover_to])}.flatten.compact.uniq

      # Skip tokens until one is found in follows
      while (token = (@lexer.first rescue @lexer.recover)) && follows.none? {|t| token === t}
        skipped = @lexer.shift
        debug("recovery", depth: options[:depth]) {"skip #{skipped.inspect}"}
      end
      debug("recovery", depth: options[:depth]) {"found #{token.inspect} in follows"}

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
      lineno = @lineno || (options[:token].lineno if options[:token].respond_to?(:lineno)) || @lexer.lineno
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
  end # class Reader
end # module RDF::Turtle
