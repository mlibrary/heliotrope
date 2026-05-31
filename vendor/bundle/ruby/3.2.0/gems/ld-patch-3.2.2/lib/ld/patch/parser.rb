require 'ebnf'
require 'ebnf/ll1/parser'
require 'ld/patch/meta'

module LD::Patch
  ##
  # A parser for the LD Patch grammar.
  #
  # @see http://www.w3.org/TR/ldpatch/#concrete-syntax
  # @see http://en.wikipedia.org/wiki/LR_parser
  class Parser
    include LD::Patch::Meta
    include LD::Patch::Terminals
    include EBNF::LL1::Parser

    ##
    # Any additional options for the parser.
    #
    # @return [Hash]
    attr_reader   :options

    ##
    # The current input string being processed.
    #
    # @return [String]
    attr_accessor :input

    ##
    # The current input tokens being processed.
    #
    # @return [Array<Token>]
    attr_reader   :tokens

    ##
    # The internal representation of the result
    # @return [Array]
    attr_accessor :result

    # Terminals passed to lexer. Order matters!
    terminal(:ANON,                 ANON) do |prod, token, input|
      input[:resource] = bnode
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |prod, token, input|
      input[:resource] = bnode(token.value[2..-1])
    end
    terminal(:IRIREF,               IRIREF, unescape: true) do |prod, token, input|
      begin
        input[:iri] = iri(token.value[1..-2])
      rescue ArgumentError => e
        raise ParseError, e.message
      end
    end
    terminal(:DOUBLE,               DOUBLE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:literal] = literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL,              DECIMAL) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      input[:literal] = literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER,              INTEGER) do |prod, token, input|
      input[:literal] = literal(token.value, datatype: RDF::XSD.integer)
    end
    terminal(:PNAME_LN,             PNAME_LN, unescape: true) do |prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      input[:iri] = ns(prefix, suffix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |prod, token, input|
      prefix = token.value[0..-2]

      # Two contexts, one when prefix is being defined, the other when being used
      case prod
      when :prefixID
        input[:prefix] = prefix
      else
        input[:iri] = ns(prefix, nil)
      end
    end
    terminal(:STRING_LITERAL_LONG_SINGLE_QUOTE, STRING_LITERAL_LONG_SINGLE_QUOTE, unescape: true) do |prod, token, input|
      input[:string] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL_LONG_QUOTE, STRING_LITERAL_LONG_QUOTE, unescape: true) do |prod, token, input|
      input[:string] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL_QUOTE, STRING_LITERAL_QUOTE, unescape: true) do |prod, token, input|
      input[:string] = token.value[1..-2]
    end
    terminal(:STRING_LITERAL_SINGLE_QUOTE, STRING_LITERAL_SINGLE_QUOTE, unescape: true) do |prod, token, input|
      input[:string] = token.value[1..-2]
    end
    terminal(:VAR1, VAR1) do |prod, token, input|
      input[:resource] = variable(token.value[1..-1])
    end

    # Keyword terminals
    terminal(nil, STR_EXPR) do |prod, token, input|
      case token.value
      when '^'             then input[:reverse] = token.value
      when '/'             then input[:slash] = token.value
      when '!'             then input[:not] = token.value
      when 'a'             then input[:predicate] = (a = RDF.type.dup; a.lexical = 'a'; a)
      when /true|false/    then input[:literal] = RDF::Literal::Boolean.new(token.value)
      when '@prefix'       then input[:prefix] = token.value
      when %r{
          AddNew|Add|A|
          Bind|B|
          Cut|C|
          DeleteExisting|Delete|DE|D|
          UpdateList|UL|
          @prefix
        }x
        input[token.value.to_sym] = token.value
      else
        #add_prod_datum(:string, token.value)
      end
    end

    terminal(:LANGTAG,              LANGTAG) do |prod, token, input|
      add_prod_datum(:language, token.value[1..-1])
    end

    # [1]	ldpatch	::=	prologue statement*
    production(:ldpatch) do |input, current, callback|
      patch = Algebra::Patch.new(*current[:statements])
      input[:ldpatch] = if prefixes.empty?
        patch
      else
        Algebra::Prefix.new(prefixes.to_a, patch)
      end
    end

    # [4]	bind	::=	("Bind" | "B") VAR1 value path? "."
    production(:bind) do |input, current, callback|
      path = Algebra::Path.new(*Array(current[:path]))
      (input[:statements] ||= []) << Algebra::Bind.new(current[:resource], current[:value], path)
    end

    # [5]	add	::=	("Add" | "A") "{" graph "}" "."
    production(:add) do |input, current, callback|
      (input[:statements] ||= []) << Algebra::Add.new(current[:graph], new: false)
    end

    # [6]	addNew	::=	("AddNew" | "AN") "{" graph "}" "."
    production(:addNew) do |input, current, callback|
      (input[:statements] ||= []) << Algebra::Add.new(current[:graph], new: true)
    end

    # [7]	delete ::=	("Delete" | "D") "{" graph "}" "."
    production(:delete) do |input, current, callback|
      (input[:statements] ||= []) << Algebra::Delete.new(current[:graph], existing: false)
    end

    # [8]	deleteExisting	::=	("DeleteExisting" | "DE") "{" graph "}" "."
    production(:deleteExisting) do |input, current, callback|
      (input[:statements] ||= []) << Algebra::Delete.new(current[:graph], existing: true)
    end

    # [9]	cut	::=	("Cut" | "C") VAR1 "."
    production(:cut) do |input, current, callback|
      (input[:statements] ||= []) << Algebra::Cut.new(current[:resource])
    end

    # [10] updateList ::= ("UpdateList" | "UL") varOrIRI predicate slice collection "."
    production(:updateList) do |input, current, callback|
      var_or_iri = current[:resource] || current[:iri]
      (input[:statements] ||= []) << Algebra::UpdateList.new(var_or_iri, current[:predicate], current[:slice1], current[:slice2], current[:collection].to_a)
    end

    # [12]	value	::=	iri | literal | VAR1
    production(:value) do |input, current, callback|
      input[:value] = current[:iri] || current[:literal] || current[:resource]
    end

    # [13] path ::= ( '/' step | constraint )*

    # [14]    step            ::=     '^' iri | iri | INTEGER
    production(:step) do |input, current, callback|
      step = case
      when current[:literal]    then Algebra::Index.new(current[:literal])
      when current[:reverse]    then Algebra::Reverse.new(current[:iri])
      else                           current[:iri]
      end
      (input[:path] ||= []) << step
    end

    # [15] constraint ::= '[' path ( '=' value )? ']' | '!'
    production(:constraint) do |input, current, callback|
      path = Algebra::Path.new(*Array(current[:path]))
      (input[:path] ||= []) << if current[:value]
        Algebra::Constraint.new(path, current[:value])
      elsif current[:path]
        Algebra::Constraint.new(path)
      else
        Algebra::Constraint.new(:unique)
      end
    end

    # [16] slice ::= INDEX? '..' INDEX?
    production(:_slice_1) do |input, current, callback|
      input[:slice1] = current[:literal]
    end
    production(:_slice_2) do |input, current, callback|
      input[:slice2] = current[:literal]
    end

    # [4t] prefixID defines a prefix mapping
    production(:prefixID) do |input, current, callback|
      prefix = current[:prefix]
      iri = current[:iri]
      debug("prefixID") {"Defined prefix #{prefix.inspect} mapping to #{iri.inspect}"}
      prefix(prefix, iri)
    end

    # [18] graph ::= triples ( '.' triples )* '.'?
    production(:graph) do |input, current, callback|
      input[:graph] = current[:triples]
    end

    # [10t*] subject ::= iri | BlankNode | collection | VAR1
    production(:subject) do |input, current, callback|
      if list = current[:collection]
        # Add collection patterns
        list.each_statement do |statement|
          (input[:triples] ||= []) << RDF::Query::Pattern.from(statement)
        end

        current[:resource] = current[:collection].subject
      end

      (input[:triples] ||= []).concat(current[:triples]) if current[:triples]
      input[:subject] = current[:resource] || current[:iri]
    end

    # [11t]   predicate       ::=     iri
    production(:predicate) do |input, current, callback|
      input[:predicate] = current[:iri]
    end

    # [12t*] object ::= iri | BlankNode | collection | blankNodePropertyList | literal | VAR1
    production(:object) do |input, current, callback|
      if list = current[:collection]
        # Add collection patterns
        list.each_statement do |statement|
          (input[:triples] ||= []) << RDF::Query::Pattern.from(statement)
        end

        current[:resource] = current[:collection].subject
      end

      # Add triples from blankNodePropertyList
      (input[:triples] ||= []).concat(current[:triples]) if current[:triples]

      if input[:object_list]
        # Part of an rdf:List collection
        input[:object_list] << (current[:resource] || current[:iri] || current[:literal])
      else
        debug("object") {"current: #{current.inspect}"}
        object = current[:resource] || current[:literal] || current[:iri]
        (input[:triples] ||= []) << RDF::Query::Pattern.new(subject: input[:subject], predicate: input[:predicate], object: object)
      end
    end

    # [14t] blankNodePropertyList ::= "[" predicateObjectList "]"
    start_production(:blankNodePropertyList) do |input, current, callback|
      current[:subject] = self.bnode
    end
    
    production(:blankNodePropertyList) do |input, current, callback|
      input[:subject] = input[:resource] = current[:subject]
      (input[:triples] ||= []).concat(current[:triples]) if current[:triples]
    end

    # [15t] collection ::= "(" object* ")"
    start_production(:collection) do |input, current, callback|
      # Tells the object production to collect and not generate statements
      current[:object_list] = []
    end
    
    production(:collection) do |input, current, callback|
      # Create an RDF list
      objects = current[:object_list]
      (input[:triples] ||= []).concat(current[:triples]) if current[:triples]
      input[:collection] = RDF::List[*objects]
    end

    # [129s]   RDFLiteral   ::=   String ( LANGTAG | ( '^^' iri ) )?
    production(:RDFLiteral) do |input, current, callback|
      if current[:string]
        lit = current.dup
        str = lit.delete(:string)
        lit[:datatype] = lit.delete(:iri) if lit[:iri]
        lit[:language] = lit.delete(:language).last.downcase if lit[:language]
        input[:literal] = RDF::Literal.new(str, **lit) if str
      end
    end

    ##
    # Initializes a new parser instance.
    #
    # @param  [String, IO, StringIO, #to_s] input
    # @param  [Hash{Symbol => Object}] options
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs
    # @option options [#to_s]    :anon_base     ("b0")
    #   Basis for generating anonymous Nodes
    # @option options [Boolean] :resolve_iris (false)
    #   Resolve prefix and relative IRIs, otherwise, when serializing the parsed SSE as S-Expressions, use the original prefixed and relative URIs along with `base` and `prefix` definitions.
    # @option options [Boolean]  :validate (false)
    #   whether to validate the parsed statements and values
    # @option options [Array] :errors
    #   array for placing errors found when parsing
    # @option options [Array] :warnings
    #   array for placing warnings found when parsing
    # @option options [Boolean] :progress
    #   Show progress of parser productions
    # @option options [Boolean] :debug
    #   Detailed debug output
    # @yield  [parser] `self`
    # @yieldparam  [LD::Patch::Parser] parser
    # @return [LD::Patch::Parser] The parser instance, or result returned from block
    def initialize(input = nil, **options, &block)
      @input = case input
      when IO, StringIO then input.read
      else input.to_s.dup
      end
      @input.encode!(Encoding::UTF_8) if @input.respond_to?(:encode!)
      @options = {anon_base: "b0", validate: false}.merge(options)
      @errors = @options[:errors]
      @options[:debug] ||= case
      when options[:progress] then 2
      when options[:validate] then (@errors ? nil : 1)
      end

      debug("base IRI") {base_uri.inspect}
      debug("validate") {validate?.inspect}

      @vars = {}

      if block_given?
        case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
        end
      end
    end

    ##
    # Accumulated errors found during processing
    # @return [Array<String>]
    attr_reader :errors

    alias_method :ll1_parse, :parse
    # Parse patch
    #
    # The result is an S-List. Productions return an array such as the following:
    #
    #   (prefix ((: <http://example/>))
    #
    # @param [Symbol, #to_s] prod The starting production for the parser.
    #   It may be a URI from the grammar, or a symbol representing the local_name portion of the grammar URI.
    # @return [SPARQL::Algebra::Operator, Object]
    # @raise [ParseError] when illegal grammar detected.
    def parse(prod = START)
      ll1_parse(@input,
        prod.to_sym,
        branch: BRANCH,
        first: FIRST,
        follow: FOLLOW,
        whitespace: WS,
        **@options
      ) do |context, *data|
        case context
        when :trace
          level, lineno, depth, *args = data
          message = args.to_sse
          d_str = depth > 100 ? ' ' * 100 + '+' : ' ' * depth
          str = "[#{lineno}](#{level})#{d_str}#{message}".chop
          if @errors && level == 0
            @errors << str
          else
            case @options[:debug]
            when Array
              @options[:debug] << str
            when TrueClass
              $stderr.puts str
            when Integer
              $stderr.puts(str) if level <= @options[:debug]
            end
          end
        end
      end

      # The last thing on the @prod_data stack is the result
      @result = case
      when !prod_data.is_a?(Hash)
        prod_data
      when prod_data.empty?
        nil
      when prod_data[:ldpatch]
        prod_data[:ldpatch]
      else
        key = prod_data.keys.first
        [key] + Array(prod_data[key])  # Creates [:key, [:triple], ...]
      end

      # Validate resulting expression
      @result.validate! if @result && validate?
      @result
    rescue EBNF::LL1::Parser::Error, EBNF::LL1::Lexer::Error =>  e
      raise LD::Patch::ParseError.new(e.message, lineno: e.lineno, token: e.token)
    end

    ##
    # Returns the Base URI defined for the parser,
    # as specified or when parsing a BASE prologue element.
    #
    # @example
    #   base  #=> RDF::URI('http://example.com/')
    #
    # @return [HRDF::URI]
    def base_uri
      RDF::URI(@options[:base_uri])
    end

    ##
    # Set the Base URI to use for this parser.
    #
    # @param  [RDF::URI, #to_s] iri
    #
    # @example
    #   base_uri = RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [RDF::URI]
    def base_uri=(iri)
      @options[:base_uri] = RDF::URI(iri)
    end

    ##
    # Returns the URI prefixes currently defined for this parser.
    #
    # @example
    #   prefixes[:dc]  #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [Hash{Symbol => RDF::URI}]
    # @since  0.3.0
    def prefixes
      @options[:prefixes] ||= {}
    end

    ##
    # Defines the given named URI prefix for this parser.
    #
    # @example Defining a URI prefix
    #   prefix :dc, RDF::URI('http://purl.org/dc/terms/')
    #
    # @example Returning a URI prefix
    #   prefix(:dc)    #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @overload prefix(name, uri)
    #   @param  [Symbol, #to_s]   name
    #   @param  [RDF::URI, #to_s] uri
    #
    # @overload prefix(name)
    #   @param  [Symbol, #to_s]   name
    #
    # @return [RDF::URI]
    def prefix(name = nil, iri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      iri.nil? ? prefixes[name] : prefixes[name] = iri
    end

    private
    ##
    # Returns `true` if parsed statements and values should be validated.
    #
    # @return [Boolean] `true` or `false`
    # @since  0.3.0
    def resolve_iris?
      @options[:resolve_iris]
    end

    ##
    # Returns `true` when resolving IRIs, otherwise BASE and PREFIX are retained in the output algebra.
    #
    # @return [Boolean] `true` or `false`
    # @since  1.0.3
    def validate?
      @options[:validate]
    end

    ##
    # Return variable allocated to an ID.
    # If no ID is provided, a new variable
    # is allocated. Otherwise, any previous assignment will be used.
    # @return [RDF::Query::Variable]
    def variable(id, distinguished = true)
      @vars[id] ||= begin
        v = RDF::Query::Variable.new(id)
        v.distinguished = distinguished
        v
      end
    end

    # Generate a BNode identifier
    def bnode(id = nil)
      unless id
        id = @options[:anon_base]
        @options[:anon_base] = @options[:anon_base].succ
      end
      # Don't use provided ID to avoid aliasing issues when re-serializing the graph, when the bnode identifiers are re-used
      (@bnode_cache ||= {})[id.to_s] ||= begin
        new_bnode = RDF::Node.new
        new_bnode.lexical = "_:#{id}"
        new_bnode
      end
    end

    # Create URIs
    def iri(value)
      # If we have a base URI, use that when constructing a new URI
      iri = if base_uri
        u = base_uri.join(value.to_s)
        u.lexical = "<#{value}>" unless u.to_s == value.to_s || resolve_iris?
        u
      else
        RDF::URI(value)
      end

      iri.validate! if validate? && iri.respond_to?(:validate)
      #iri = RDF::URI.intern(iri) if intern?
      iri
    end

    def ns(prefix, suffix)
      error("pname", "undefined prefix #{prefix.inspect}") unless prefix(prefix)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug {"ns(#{prefix.inspect}): base: '#{base}', suffix: '#{suffix}'"}
      iri = iri(base + suffix.to_s)
      # Cause URI to be serialized as a lexical
      iri.lexical = "#{prefix}:#{suffix}" unless resolve_iris?
      iri
    end

    # Create a literal
    def literal(value, **options)
      options = options.dup
      # Internal representation is to not use xsd:string, although it could arguably go the other way.
      options.delete(:datatype) if options[:datatype] == RDF::XSD.string
      debug("literal") do
        "value: #{value.inspect}, " +
        "options: #{options.inspect}, " +
        "validate: #{validate?.inspect}, "
      end
      RDF::Literal.new(value, validate: validate?, **options)
    end
  end
end


# Update RDF::Node to set lexical representation of BNode
##
# Extensions for RDF::URI
class RDF::Node
  # Original lexical value of this URI to allow for round-trip serialization.
  def lexical=(value); @lexical = value; end
  def lexical; @lexical; end
end
