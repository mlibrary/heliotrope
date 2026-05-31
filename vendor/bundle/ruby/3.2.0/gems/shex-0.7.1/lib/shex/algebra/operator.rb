require 'sparql/algebra'
require 'json/ld/preloaded'
require 'shex/shex_context'

module ShEx::Algebra

  ##
  # The ShEx operator.
  #
  # @abstract
  class Operator
    extend SPARQL::Algebra::Expression
    include RDF::Util::Logger

    # Location of schema including this operator
    attr_accessor :schema

    # Initialization options
    attr_accessor :options

    ARITY = -1 # variable arity

    ##
    # Initializes a new operator instance.
    #
    # @overload initialize(*operands)
    #   @param  [Array<RDF::Term>] operands
    #
    # @overload initialize(*operands, **options)
    #   @param  [Array<RDF::Term>] operands
    #   @param  [Hash{Symbol => Object}] options
    #     any additional options
    #   @option options [Boolean] :memoize (false)
    #     whether to memoize results for particular operands
    #   @option options [RDF::Resource] :id
    #     Identifier of the operator
    # @raise  [TypeError] if any operand is invalid
    def initialize(*operands, **options)
      @options  = options.dup
      @operands = operands.map! do |operand|
        case operand
          when Array
            operand.each do |op|
              op.parent = self if op.respond_to?(:parent=)
            end
            operand
          when Operator, RDF::Term, RDF::Query, RDF::Query::Pattern, Array, Symbol
            operand.parent = self if operand.respond_to?(:parent=)
            operand
          when TrueClass, FalseClass, Numeric, String, DateTime, Date, Time
            RDF::Literal(operand)
          when NilClass
            raise ArgumentError, "Found nil operand for #{self.class.name}"
          else raise TypeError, "invalid ShEx::Algebra::Operator operand: #{operand.inspect}"
        end
      end

      @id = options[:id]
    end

    ##
    # Is this shape closed?
    # @return [Boolean]
    def closed?
      operands.include?(:closed)
    end

    ##
    # Semantic Actions
    # @return [Array<SemAct>]
    def semantic_actions
      operands.select {|o| o.is_a?(SemAct)}
    end

    # Does this operator include TripleExpression?
    def triple_expression?; false; end

    # Does this operator a SemAct?
    def semact?; false; end

    ##
    # On a result instance, the focus of the expression
    def focus
      Array(operands.detect {|op| op.is_a?(Array) && op[0] == :focus} || [:focus])[1]
    end
    def focus=(node)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :focus}
      operands << [:focus, node]
    end

    ##
    # On a result instance, the statements that matched this expression.
    # @return [Array<Statement>]
    def matched
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :matched} || [:matched])[1..-1])
    end
    def matched=(statements)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :matched}
      operands << statements.unshift(:matched) unless (statements || []).empty?
    end

    ##
    # On a result instance, the statements that did not match this expression (failure only).
    # @return [Array<Statement>]
    def unmatched
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :unmatched} || [:unmatched])[1..-1])
    end
    def unmatched=(statements)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :unmatched}
      operands << statements.unshift(:unmatched) unless (statements || []).empty?
    end

    ##
    # On a result instance, the sub-expressions which were matched.
    # @return [Array<Operator>]
    def satisfied
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :satisfied} || [:satisfied])[1..-1])
    end
    def satisfied=(ops)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :satisfied}
      operands << ops.unshift(:satisfied) unless (ops || []).empty?
    end

    ##
    # On a result instance, the sub-satisfieables which were not satisfied. (failure only).
    # @return [Array<Operator>]
    def unsatisfied
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :unsatisfied} || [:unsatisfied])[1..-1])
    end
    def unsatisfied=(ops)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :unsatisfied}
      operands << ops.unshift(:unsatisfied) unless (ops || []).empty?
    end

    ##
    # On a result instance, the failure message. (failure only).
    # @return [String]
    def message
      (operands.detect {|op| op.is_a?(Array) && op[0] == :message} || [:message])[1..-1]
    end
    def message=(str)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :message}
      operands << [:message, str]
    end

    ##
    # Duplication this operand, and add `matched`, `unmatched`, `satisfied`, and `unsatisfied` operands for accessing downstream.
    #
    # @return [Operand]
    def satisfy(focus: nil, matched: nil, unmatched: nil, satisfied: nil, unsatisfied: nil, message: nil, **opts)
      log_debug(self.class.const_get(:NAME), "satisfied", **opts) unless message
      expression = self.dup
      expression.message = message if message
      expression.focus = focus if focus
      expression.matched = Array(matched) if matched
      expression.unmatched = Array(unmatched) if unmatched
      expression.satisfied = Array(satisfied) if satisfied
      expression.unsatisfied = Array(unsatisfied) if unsatisfied
      expression
    end

    ##
    # Exception handling
    def not_matched(message, **opts, &block)
      expression = opts.fetch(:expression, self).satisfy(message: message, **opts)
      exception = opts.fetch(:exception, ShEx::NotMatched)
      status(message, **opts) {(block_given? ? block.call : "") + "expression: #{expression.to_sxp}"}
      raise exception.new(message, expression: expression)
    end

    def not_satisfied(message, **opts)
      expression = opts.fetch(:expression, self).satisfy(message: message, **opts)
      exception = opts.fetch(:exception, ShEx::NotSatisfied)
      status(message, **opts) {(block_given? ? block.call : "") + "expression: #{expression.to_sxp}"}
      raise exception.new(message, expression: expression)
    end

    def structure_error(message, **opts)
      expression = opts.fetch(:expression, self)
      exception = opts.fetch(:exception, ShEx::StructureError)
      log_error(message, depth: options.fetch(:depth, 0), exception: exception) {"expression: #{expression.to_sxp}"}
    end

    def status(message, **opts, &block)
      log_debug(self.class.const_get(:NAME).to_s + (@id ? "(#{@id})" : ""), message, **opts, &block)
      true
    end

    ##
    # The operands to this operator.
    #
    # @return [Array]
    attr_reader :operands

    ##
    # The id (or subject) of this operand
    # @return [RDF::Resource]
    attr_accessor :id

    ##
    # Logging support (reader is in RDF::Util::Logger)
    # @return [Logger]
    attr_writer :logger

    ##
    # Returns the operand at the given `index`.
    #
    # @param  [Integer] index
    #   an operand index in the range `(0...(operands.count))`
    # @return [RDF::Term]
    def operand(index = 0)
      operands[index]
    end

    ##
    # Expressions are all operands which are Operators or RDF::Resource
    # @return [RDF::Resource, Operand]
    def expressions
      @expressions = operands.
        select {|op| op.is_a?(RDF::Resource) || op.is_a?(ShapeExpression) || op.is_a?(TripleExpression)}
    end

    ##
    # The first expression from {#expressions}.
    # @return [RDF::Resource, Operand]
    def expression
      expressions.first
    end

    ##
    # References are all operands which are RDF::Resource
    # @return [RDF::Resource, Operand]
    def references
      @references = operands.select {|op| op.is_a?(RDF::Resource)}
    end

    ##
    # Returns the binary S-Expression (SXP) representation of this operator.
    #
    # @return [Array]
    # @see    https://en.wikipedia.org/wiki/S-expression
    def to_sxp_bin
      [self.class.const_get(:NAME)] +
      (id ? [[:id, id]] : []) +
      (operands || []).map(&:to_sxp_bin)
    end

    ##
    # Returns an S-Expression (SXP) representation of this operator
    #
    # @return [String]
    def to_sxp(**options)
      require 'sparql/algebra/sxp_extensions'

      to_sxp_bin.to_sxp(**options)
    end

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param [Hash] operator
    # @param [Hash] options ({})
    # @option options [RDF::URI] :base
    # @option options [Hash{String => RDF::URI}] :prefixes
    # @return [Operator]
    def self.from_shexj(operator, **options)
      options[:context] ||= JSON::LD::Context.parse(ShEx::CONTEXT)
      operands = []
      id = nil

      operator.each do |k, v|
        case k
        when /length|clusive|digits/           then operands << [k.to_sym, RDF::Literal(v)]
        when 'id'                              then id = iri(v, **options)
        when 'flags'                           then ; # consumed in pattern below
        when 'min', 'max'                      then operands << [k.to_sym, (v == -1 ? '*' : v)]
        when 'inverse', 'closed'               then operands << k.to_sym
        when 'nodeKind'                        then operands << v.to_sym
        when 'object'                          then operands << value(v, **options)
        when 'languageTag'                     then operands << v
        when 'pattern'
          # Include flags as well
          operands << [:pattern, RDF::Literal(v), operator['flags']].compact
        when 'start'
          if v.is_a?(String)
            operands << Start.new(iri(v, **options))
          else
            operands << Start.new(ShEx::Algebra.from_shexj(v, **options))
          end
        when '@context'                        then
          options[:context] = JSON::LD::Context.parse(v)
          options[:base_uri] ||= options[:context].base
        when 'shapes'
          operands << case v
          when Array
            [:shapes] + v.map {|vv| ShEx::Algebra.from_shexj(vv, **options)}
          else
            raise "Expected value of shapes #{v.inspect}"
          end
        when 'stem', 'name'
          # Value may be :wildcard for stem
          if [IriStem, IriStemRange, SemAct].include?(self)
            operands << (v.is_a?(Symbol) ? v : value(v, **options))
          else
            operands << v
          end
        when 'predicate' then operands << [:predicate, iri(v, **options)]
        when 'extra', 'datatype'
          v = [v] unless v.is_a?(Array)
          operands << (v.map {|op| iri(op, **options)}).unshift(k.to_sym)
        when 'exclusions'
          v = [v] unless v.is_a?(Array)
          operands << v.map do |op|
            if op.is_a?(Hash) && op.has_key?('type')
              ShEx::Algebra.from_shexj(op, **options)
            elsif [IriStem, IriStemRange].include?(self)
              value(op, **options)
            else
              RDF::Literal(op)
            end
          end.unshift(:exclusions)
        when 'semActs', 'startActs', 'annotations'
          v = [v] unless v.is_a?(Array)
          operands += v.map {|op| ShEx::Algebra.from_shexj(op, **options)}
        when 'expression', 'expressions', 'shapeExpr', 'shapeExprs', 'valueExpr'
          v = [v] unless v.is_a?(Array)
          operands += v.map do |op|
            # It's a URI reference to a Shape
            op.is_a?(String) ? iri(op, **options) : ShEx::Algebra.from_shexj(op, **options) 
          end
        when 'code'
          operands << v
        when 'values'
          v = [v] unless v.is_a?(Array)
          operands += v.map do |op|
            Value.new(value(op, **options))
          end
        end
      end

      new(*operands, **options.merge(id: id))
    end

    def json_type
      self.class.name.split('::').last
    end

    def to_json(options = nil)
      self.to_h.to_json(options)
    end

    ##
    # Create a hash version of the operator, suitable for turning into JSON.
    # @return [Hash]
    def to_h
      obj = json_type == 'Schema' ? {'@context' => ShEx::CONTEXT} :  {}
      obj['id'] = id.to_s if id
      obj['type'] = json_type
      operands.each do |op|
        case op
        when Array
          # First element should be a symbol
          case sym = op.first
          when :datatype        then obj['datatype'] = op.last.to_s
          when :exclusions
            obj['exclusions'] = Array(op[1..-1]).map do |v|
              case v
              when Operator then v.to_h
              else v.to_s
              end
            end
          when :extra           then (obj['extra'] ||= []).concat Array(op[1..-1]).map(&:to_s)
          when :pattern
            obj['pattern'] = op[1]
            obj['flags'] = op[2] if op[2]
          when :shapes          then obj['shapes'] = Array(op[1..-1]).map {|v| v.to_h}
          when :minlength,
               :maxlength,
               :length,
               :mininclusive,
               :maxinclusive,
               :minexclusive,
               :maxexclusive,
               :totaldigits,
               :fractiondigits  then obj[op.first.to_s] = op.last.object
          when :min, :max       then obj[op.first.to_s] = op.last == '*' ? -1 : op.last
          when :predicate       then obj[op.first.to_s] = op.last.to_s
          when :base, :prefix
            # Ignore base and prefix
          when Symbol           then obj[sym.to_s] = Array(op[1..-1]).map(&:to_h)
          else
            raise "Expected array to start with a symbol for #{self}"
          end
        when :wildcard  then obj['stem'] = {'type' => 'Wildcard'}
        when Annotation then (obj['annotations'] ||= []) << op.to_h
        when SemAct     then (obj[is_a?(Schema) ? 'startActs' : 'semActs'] ||= []) << op.to_h
        when Start
         obj['start'] =  case op.operands.first
          when RDF::Resource then op.operands.first.to_s
          else                    op.operands.first.to_h
          end
        when RDF::Value
          case self
          when Stem, StemRange
            obj['stem'] =  case op
            when Operator then op.to_h
            else op.to_s
            end
          when SemAct           then obj[op.is_a?(RDF::URI) ? 'name' : 'code'] = op.to_s
          when TripleConstraint then obj['valueExpr'] = op.to_s
          when Shape            then obj['expression'] = op.to_s
          when EachOf, OneOf    then (obj['expressions'] ||= []) << op.to_s
          when And, Or          then (obj['shapeExprs'] ||= []) << op.to_s
          when Not              then obj['shapeExpr'] = op.to_s
          when Language         then obj['languageTag'] = op.to_s
          else
            raise "How to serialize Value #{op.inspect} to json for #{self}"
          end
        when Symbol
          case self
          when NodeConstraint   then obj['nodeKind'] = op.to_s
          when Shape            then obj['closed'] = true
          when TripleConstraint then obj['inverse'] = true
          else
            raise "How to serialize Symbol #{op.inspect} to json for #{self}"
          end
        when TripleConstraint, EachOf, OneOf
          case self
          when EachOf, OneOf
            (obj['expressions'] ||= []) << op.to_h
          else
            obj['expression'] = op.to_h
          end
        when NodeConstraint
          case self
          when And, Or
            (obj['shapeExprs'] ||= []) << op.to_h
          when Not
            obj['shapeExpr'] = op.to_h
          else
            obj['valueExpr'] = op.to_h
          end
        when And, Or, Shape, Not
          case self
          when And, Or
            (obj['shapeExprs'] ||= []) << op.to_h
          when TripleConstraint
            obj['valueExpr'] = op.to_h
          else
            obj['shapeExpr'] = op.to_h
          end
        when Value
          obj['values'] ||= []
          Array(op).map {|o| o.operands}.flatten.each do |oo|
            obj['values'] << serialize_value(oo)
          end
        else
          raise "How to serialize #{op.inspect} to json for #{self}"
        end
      end
      obj
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
      @options[:base_uri]
    end

    # Create URIs
    # @param [RDF::Value, String] value
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :base_uri
    # @option options [Hash{String => RDF::URI}] :prefixes
    # @option options [JSON::LD::Context] :context
    # @return [RDF::Value]
    def iri(value, options = @options)
      self.class.iri(value, **options)
    end

    # Create URIs
    # @param  (see #iri)
    # @option (see #iri)
    # @return (see #iri)
    def self.iri(value, **options)
      # If we have a base URI, use that when constructing a new URI
      base_uri = options[:base_uri]

      case value
      when Hash
        # A JSON-LD node reference
        v = options[:context].expand_value(value)
        raise "Expected #{value.inspect} to be a JSON-LD Node Reference" unless JSON::LD::Utils.node_reference?(v)
        self.iri(v['@id'], **options)
      when RDF::URI
        if base_uri && value.relative?
          base_uri.join(value)
        else
          value
        end
      when RDF::Value then value
      when /^_:/ then
        id = value[2..-1].to_s
        RDF::Node.intern(id)
      when /^(\w+):(\S+)$/
        prefixes = options.fetch(:prefixes, {})
        if prefixes.has_key?($1)
          prefixes[$1].join($2)
        elsif RDF.type == value
          a = RDF.type.dup; a.lexical = 'a'; a
        elsif options[:context]
          options[:context].expand_iri(value, vocab: true)
        else
          RDF::URI(value)
        end
      else
        if base_uri
          base_uri.join(value)
        else
          RDF::URI(value)
        end
      end
    end

    # Create Values, with "clever" matching to see if it might be a value, IRI or BNode.
    # @param [RDF::Value, String] value
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :base_uri
    # @option options [Hash{String => RDF::URI}] :prefixes
    # @return [RDF::Value]
    def value(value, options = @options)
      self.class.value(value, **options)
    end

    # Create Values, with "clever" matching to see if it might be a value, IRI or BNode.
    # @param  (see #value)
    # @option (see #value)
    # @return (see #value)
    def self.value(value, **options)
      # If we have a base URI, use that when constructing a new URI
      case value
      when Hash
        # Either a value object or a node reference
        if value['uri'] || value['@id']
          iri(value['uri'] || value['@id'], **options)
        elsif value['value'] || value['@value']
          RDF::Literal(value['value'] || value['@value'], datatype: value['type'] || value['@type'], language: value['language'] || value['@language'])
        else
          ShEx::Algebra.from_shexj(value, **options)
        end
      else iri(value, **options)
      end
    end

    ##
    # Serialize a value, either as JSON, or as modififed N-Triples
    #
    # @param [RDF::Value, Operator] value
    # @return [String]
    def serialize_value(value)
      case value
        when RDF::Literal
          {'value' => value.to_s}.
          merge(value.has_datatype? ? {'type' => value.datatype.to_s} : {}).
          merge(value.has_language? ? {'language' => value.language.to_s} : {})
        when RDF::Resource
          value.to_s
        when String
          {'value' => value}
        else value.to_h
      end
    end

    ##
    # Returns a developer-friendly representation of this operator.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s%s)>", self.class.name, __id__, ("id: #{id} " if id), operands.inspect)
    end

    ##
    # Comparison does not consider operand order
    # @param  [Statement] other
    # @return [Boolean]
    def eql?(other)
      other.class == self.class &&
        other.id == self.id &&
        other.operands.sort_by(&:to_s) == self.operands.sort_by(&:to_s)
    end
    alias_method :==, :eql?

    ##
    # Enumerate via depth-first recursive descent over operands, yielding each operator
    # @param [Boolean] include_self
    # @yield operator
    # @yieldparam [Object] operator
    # @return [Enumerator]
    def each_descendant(include_self = false, &block)
      if block_given?

        block.call(self) if include_self

        operands.each do |operand|
          case operand
          when Array
            operand.each do |op|
              op.each_descendant(true, &block) if op.respond_to?(:each_descendant)
            end
          else
            operand.each_descendant(true, &block) if operand.respond_to?(:each_descendant)
          end
        end
      end
      enum_for(:each_descendant)
    end
    alias_method :descendants, :each_descendant
    alias_method :each, :each_descendant

    ##
    # Parent expression, if any
    #
    # @return [Operator]
    def parent; @options[:parent]; end

    ##
    # Parent operator, if any
    #
    # @return [Operator]
    def parent=(operator)
      @options[:parent]= operator
    end

    ##
    # Find a ShapeExpression or TripleExpression by identifier
    # @param [#to_s] id
    # @return [TripleExpression, ShapeExpression]
    def find(id)
      each_descendant(false).detect {|op| op.id == id}
    end

    ##
    # Ancestors of this Operator
    # @return [Array<Operator>]
    #def ancestors
    #  parent.is_a?(Operator) ? ([parent] + parent.ancestors) : []
    #end

    ##
    # Validate all operands, operator specific classes should override for operator-specific validation.
    #
    # A schema **must not** contain any shape expression `S` with negated references, either directly or transitively, to `S`.
    #
    # @return [SPARQL::Algebra::Expression] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate!
      operands.each do |op|
        op.validate! if op.respond_to?(:validate!)
        if op.is_a?(RDF::Resource) && (is_a?(ShapeExpression) || is_a?(TripleExpression))
          ref = schema.find(op)
          structure_error("Missing reference: #{op}") if ref.nil?
          #if ancestors.unshift(self).include?(ref)
          #  structure_error("Self-recursive reference to #{op}")
          #end
          structure_error("Self referencing shape: #{operands.first}") if ref == self
        end
      end
      self
    end

  def dup
    operands = @operands.map {|o| o.dup rescue o}
    self.class.new(*operands, id: @id)
  end

  protected
    ##
    # A unary operator.
    #
    # Operators of this kind take one operand.
    #
    # @abstract
    class Unary < Operator
      ARITY = 1

      ##
      # @param  [RDF::Term] arg1
      #   the first operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, **options)
        raise ArgumentError, "wrong number of arguments (given 2, expected 1)" unless options.is_a?(Hash)
        super
      end
    end # Unary

    ##
    # A binary operator.
    #
    # Operators of this kind take two operands.
    #
    # @abstract
    class Binary < Operator
      ARITY = 2

      ##
      # @param  [RDF::Term] arg1
      #   the first operand
      # @param  [RDF::Term] arg2
      #   the second operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, arg2, **options)
        raise ArgumentError, "wrong number of arguments (given 3, expected 2)" unless options.is_a?(Hash)
        super
      end
    end # Binary
  end
end