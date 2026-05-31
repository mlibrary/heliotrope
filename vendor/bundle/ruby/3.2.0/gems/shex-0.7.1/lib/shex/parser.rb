# -*- encoding: utf-8 -*-
require 'ebnf'
require 'ebnf/peg/parser'
require 'shex/meta'

module ShEx
  ##
  # A parser for the ShEx grammar.
  #
  # @see https://www.w3.org/2005/01/yacker/uploads/ShEx3?lang=perl&markup=html#productions
  # @see https://en.wikipedia.org/wiki/LR_parser
  class Parser
    include ShEx::Terminals
    include EBNF::PEG::Parser
    include RDF::Util::Logger

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
    # The internal representation of the result using hierarchy of RDF objects and ShEx::Operator
    # objects.
    # @return [Array]
    # @see https://ruby-rdf.github.io/sparql/SPARQL/Algebra
    attr_accessor :result

    # Terminals passed to lexer. Order matters!
    terminal(:CODE,                 CODE, unescape: true) do |value|
      # { foo %}
      # Keep surrounding whitespace for now
      value[1..-2].sub(/%\s*$/, '') # Drop {} and %
    end
    terminal(:REPEAT_RANGE,         REPEAT_RANGE) do |value|
      card = value[1..-2].split(',').map {|v| v =~ /^\d+$/ ? v.to_i : v}
      card[1] = value.include?(',') ? '*' : card[0] if card.length == 1
      {min: card[0], max: card[1]}
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |value|
      bnode(value[2..-1])
    end
    terminal(:IRIREF,               IRIREF, unescape: true) do |value|
      begin
        iri(value[1..-2])
      rescue ArgumentError => e
        raise Error, e.message
      end
    end
    terminal(:DOUBLE,               DOUBLE) do |value|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = value.sub(/\.([eE])/, '.0\1')
      literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL,              DECIMAL) do |value|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER,              INTEGER) do |value|
      literal(value, datatype: RDF::XSD.integer)
    end
    terminal(:PNAME_LN,             PNAME_LN, unescape: true) do |value|
      prefix, suffix = value.split(":", 2)
      error(nil, "Compact IRI missing prefix definition: #{prefix}", production: :PNAME_LN) unless prefix(prefix)
      ns(prefix, suffix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |value|
      value[0..-2]
    end
    terminal(:ATPNAME_LN,             ATPNAME_LN, unescape: true) do |value, parent_prod|
      prefix, suffix = value.split(":", 2)
      prefix.sub!(/^@#{WS}*/, '')
      ns(prefix, suffix)
    end
    terminal(:ATPNAME_NS,             ATPNAME_NS) do |value|
      prefix = value[0..-2]
      prefix.sub!(/^@\s*/, '')

      ns(prefix, nil)
    end
    terminal(:LANGTAG,              LANGTAG) do |value|
      value[1..-1]
    end
    terminal(:LANG_STRING_LITERAL_LONG1, LANG_STRING_LITERAL_LONG1, unescape: true) do |value|
      s, _, l = value[3..-1].rpartition("'''@")
      [s, language: l]
    end
    terminal(:LANG_STRING_LITERAL_LONG2, LANG_STRING_LITERAL_LONG2, unescape: true) do |value|
      s, _, l = value[3..-1].rpartition('"""@')
      [s, language: l]
    end
    terminal(:LANG_STRING_LITERAL1,      LANG_STRING_LITERAL1, unescape: true) do |value|
      s, _, l = value[1..-1].rpartition("'@")
      [s, language: l]
    end
    terminal(:LANG_STRING_LITERAL2,      LANG_STRING_LITERAL2, unescape: true) do |value|
      s, _, l = value[1..-1].rpartition('"@')
      [s, language: l]
    end
    terminal(:STRING_LITERAL_LONG1, STRING_LITERAL_LONG1, unescape: true) do |value|
      value[3..-4]
    end
    terminal(:STRING_LITERAL_LONG2, STRING_LITERAL_LONG2, unescape: true) do |value|
      value[3..-4]
    end
    terminal(:STRING_LITERAL1,      STRING_LITERAL1, unescape: true) do |value|
      value[1..-2]
    end
    terminal(:STRING_LITERAL2,      STRING_LITERAL2, unescape: true) do |value|
      value[1..-2]
    end
    terminal(:REGEXP,               REGEXP)
    terminal(:RDF_TYPE,             RDF_TYPE) do |value|
      (a = RDF.type.dup; a.lexical = 'a'; a)
    end

    # Productions
    # [1]     shexDoc               ::= directive* ((notStartAction | startActions) statement*)?
    start_production(:shexDoc, as_hash: true, clear_packrat: true)
    production(:shexDoc) do |value|
      expressions = []
      prefixes = []

      # directive *
      expressions += value[:_shexDoc_1]

      # ((notStartAction | startActions) statement*)?
      if value = value[:_shexDoc_2]
        # These may start with codeDecl or start. otherwise, they are all shapes
        expressions += Array(value[:_shexDoc_4])
        expressions += Array(value[:_shexDoc_5])
      end

      # Extract declarations, startacts and start from expressions
      declarations, expressions = expressions.partition {|op| op.is_a?(Array)}
      prefixes, bases = declarations.partition {|op| op.first == :prefix}
      semacts, expressions = expressions.partition {|op| op.is_a?(Algebra::SemAct)}
      starts, expressions = expressions.partition {|op| op.is_a?(Algebra::Start)}

      operands = []
      operands += bases unless bases.empty?
      unless prefixes.empty?
        operands << [:prefix, prefixes.map {|p| p[1,2]}]
      end
      operands += semacts
      operands += starts
      operands << expressions.unshift(:shapes) unless expressions.empty?
      Algebra::Schema.new(*operands, **self.options)
    end
    start_production(:_shexDoc_2, as_hash: true)
    start_production(:_shexDoc_3, as_hash: true)

    # [2]     directive             ::= baseDecl | prefixDecl | importDecl

    # [3]     baseDecl              ::= "BASE" IRIREF
    start_production(:baseDecl, as_hash: true, insensitive_strings: :lower)
    production(:baseDecl) do |value|
      self.base_uri = iri(value[:IRIREF])
      [:base, self.base_uri]
    end

    # [4]     prefixDecl            ::= "PREFIX" PNAME_NS IRIREF
    start_production(:prefixDecl, as_hash: true, insensitive_strings: :lower)
    production(:prefixDecl) do |value|
      pfx = value[:PNAME_NS]
      prefix(pfx, value[:IRIREF])
      [:prefix, pfx.to_s, value[:IRIREF]]
    end

    # [4]     importDecl            ::= "IMPORT" IRIREF
    start_production(:importDecl, as_hash: true, insensitive_strings: :lower)
    production(:importDecl) do |value|
      Algebra::Import.new(value[:IRIREF], **self.options)
    end

    # [5]     notStartAction        ::= start | shapeExprDecl
    # [6]     start                 ::= "START" '=' inlineShapeExpression
    start_production(:start, as_hash: true, insensitive_strings: :lower)
    production(:start) do |value|
      Algebra::Start.new(value[:inlineShapeExpression], **self.options)
    end

    # [7]     startActions          ::= codeDecl+

    # [8]     statement             ::= directive | notStartAction

    # [9]     shapeExprDecl         ::= shapeExprLabel (shapeExpression | "EXTERNAL")
    start_production(:shapeExprDecl, as_hash: true)
    production(:shapeExprDecl) do |value|
      id = value[:shapeExprLabel]
      expression = case value[:_shapeExprDecl_1]
      when Algebra::NodeConstraint, Algebra::Or, Algebra::And, Algebra::Not, Algebra::Shape, RDF::Resource
        value[:_shapeExprDecl_1]
      when /external/i
         Algebra::External.new(**options)
      else
        Algebra::Shape.new(**options)
      end
      expression.id = id if id && !expression.is_a?(RDF::Resource)

      expression
    end

    # [10]    shapeExpression       ::= shapeOr
    production(:shapeExpression) do |value|
      value.first[:shapeOr]
    end

    # [11]    inlineShapeExpression ::= inlineShapeOr
    production(:inlineShapeExpression) do |value|
      value.first[:inlineShapeOr]
    end

    # [12]    shapeOr               ::= shapeAnd ("OR" shapeAnd)*
    start_production(:shapeOr, as_hash: true)
    production(:shapeOr) do |value|
      if value[:_shapeOr_1].empty?
        value[:shapeAnd]
      else
        lhs = value[:_shapeOr_1].map {|v| v.last[:shapeAnd]}
        Algebra::Or.new(value[:shapeAnd], *lhs, **self.options)
      end
    end
    start_production(:_shapeOr_2, insensitive_strings: :lower)

    # [13]    inlineShapeOr         ::= inlineShapeAnd ("OR" inlineShapeAnd)*
    start_production(:inlineShapeOr, as_hash: true)
    production(:inlineShapeOr) do |value|
      if value[:_inlineShapeOr_1].empty?
        value[:inlineShapeAnd]
      else
        lhs = value[:_inlineShapeOr_1].map {|v| v.last[:inlineShapeAnd]}
        Algebra::Or.new(value[:inlineShapeAnd], *lhs, **self.options)
      end
    end
    start_production(:_inlineShapeOr_2, insensitive_strings: :lower)

    # [14]    shapeAnd              ::= shapeNot ("AND" shapeNot)*
    start_production(:shapeAnd, as_hash: true)
    production(:shapeAnd) do |value|
      if value[:_shapeAnd_1].empty?
        value[:shapeNot]
      else
        lhs = value[:_shapeAnd_1].map {|v| v.last[:shapeNot]}
        Algebra::And.new(value[:shapeNot], *lhs, **self.options)
      end
    end
    start_production(:_shapeAnd_2, insensitive_strings: :lower)

    # [15]    inlineShapeAnd        ::= inlineShapeNot ("AND" inlineShapeNot)*
    start_production(:inlineShapeAnd, as_hash: true)
    production(:inlineShapeAnd) do |value|
      if value[:_inlineShapeAnd_1].empty?
        value[:inlineShapeNot]
      else
        lhs = value[:_inlineShapeAnd_1].map {|v| v.last[:inlineShapeNot]}
        Algebra::And.new(value[:inlineShapeNot], *lhs, **self.options)
      end
    end
    start_production(:_inlineShapeAnd_2, insensitive_strings: :lower)

    # [16]    shapeNot              ::= "NOT"? shapeAtom
    start_production(:shapeNot, as_hash: true)
    production(:shapeNot) do |value|
      atom = value[:shapeAtom]
      value[:_shapeNot_1] ? Algebra::Not.new(atom || Algebra::Shape.new(**options), **self.options) : atom
    end
    start_production(:_shapeNot_1, insensitive_strings: :lower)

    # [17]    inlineShapeNot        ::= "NOT"? inlineShapeAtom
    start_production(:inlineShapeNot, as_hash: true)
    production(:inlineShapeNot) do |value|
      atom = value[:inlineShapeAtom]
      value[:_inlineShapeNot_1] ? Algebra::Not.new(atom || Algebra::Shape.new(**options), **self.options) : atom
    end
    start_production(:_inlineShapeNot_1, insensitive_strings: :lower)

    # [18]    shapeAtom             ::= nonLitNodeConstraint shapeOrRef?
    #                                 | litNodeConstraint
    #                                 | shapeOrRef nonLitNodeConstraint?
    #                                 | "(" shapeExpression ")"
    #                                 | '.'  # no constraint
    production(:shapeAtom) do |value|
      expressions = case
      when value.is_a?(Algebra::Operator)
        [value]
      when value == '.' then []
      when value[:nonLitNodeConstraint]
        [value[:nonLitNodeConstraint], value[:_shapeAtom_4]].compact
      when value[:shapeOrRef]
        [value[:shapeOrRef], value[:_shapeAtom_5]].compact
      when value[:_shapeAtom_3]
        value[:_shapeAtom_3]
      else []
      end

      case expressions.length
      when 0 then nil
      when 1 then expressions.first
      else Algebra::And.new(*expressions, **self.options)
      end
    end
    start_production(:_shapeAtom_1, as_hash: true)
    start_production(:_shapeAtom_2, as_hash: true)
    production(:_shapeAtom_3) do |value|
      value[1][:shapeExpression]
    end

    # [19]   shapeAtomNoRef        ::= nonLitNodeConstraint shapeOrRef?
    #                                | litNodeConstraint
    #                                | shapeDefinition nonLitNodeConstraint?
    #                                | "(" shapeExpression ")"
    #                                | '.'  # no constraint
    production(:shapeAtomNoRef) do |value|
      expressions = case
      when value.is_a?(Algebra::Operator)
        [value]
      when value == '.' then []
      when value[:nonLitNodeConstraint]
        [value[:nonLitNodeConstraint], value[:_shapeAtomNoRef_4]].compact
      when value[:shapeDefinition]
        [value[:shapeDefinition], value[:_shapeAtomNoRef_5]].compact
      when value[:_shapeAtomNoRef_3]
        value[:_shapeAtomNoRef_3]
      else []
      end

      case expressions.length
      when 0 then nil
      when 1 then expressions.first
      else Algebra::And.new(*expressions, **self.options)
      end
    end
    start_production(:_shapeAtomNoRef_1, as_hash: true)
    start_production(:_shapeAtomNoRef_2, as_hash: true)
    production(:_shapeAtomNoRef_3) do |value|
      value[1][:shapeExpression]
    end

    # [20]    inlineShapeAtom       ::= nonLitNodeConstraint inlineShapeOrRef?
    #                                 | litNodeConstraint
    #                                 | inlineShapeOrRef nonLitNodeConstraint?
    #                                 | "(" shapeExpression ")"
    #                                 | '.'  # no constraint
    production(:inlineShapeAtom) do |value|
      expressions = case
      when value == '.' then []
      when value.is_a?(Algebra::Operator)
        [value]
      when value[:nonLitNodeConstraint]
        [value[:nonLitNodeConstraint], value[:_inlineShapeAtom_4]].compact
      when value[:inlineShapeOrRef]
        [value[:inlineShapeOrRef], value[:__inlineShapeAtom_5]].compact
      when value[:_inlineShapeAtom_3]
        value[:_inlineShapeAtom_3]
      else []
      end

      case expressions.length
      when 0 then nil
      when 1 then expressions.first
      else Algebra::And.new(*expressions, **self.options)
      end
    end
    start_production(:_inlineShapeAtom_1, as_hash: true)
    start_production(:_inlineShapeAtom_2, as_hash: true)
    production(:_inlineShapeAtom_3) do |value|
      value[1][:shapeExpression]
    end

    # [21]    shapeOrRef            ::= shapeDefinition | shapeRef
    # [22]    inlineShapeOrRef      ::= inlineShapeDefinition | shapeRef

    # [23]    shapeRef              ::= ATPNAME_LN | ATPNAME_NS | '@' shapeExprLabel
    production(:shapeRef) do |value|
      value.is_a?(Array) ? value.last[:shapeExprLabel] : value
    end

    # [24]    litNodeConstraint     ::= "LITERAL" xsFacet*
    #                                 | datatype xsFacet*
    #                                 | valueSet xsFacet*
    #                                 | numericFacet+
    start_production(:_litNodeConstraint_1, as_hash: true, insensitive_strings: :lower)
    production(:_litNodeConstraint_1) do |value|
      # LITERAL" xsFacet*
      facets = value[:_litNodeConstraint_5]
      validate_facets(facets, :litNodeConstraint)
      Algebra::NodeConstraint.new(:literal, *facets, **self.options)
    end
    start_production(:_litNodeConstraint_2, as_hash: true)
    production(:_litNodeConstraint_2) do |value|
      # datatype xsFacet*
      facets = value[:_litNodeConstraint_6]
      validate_facets(facets, :litNodeConstraint)

      # Numeric Facet Constraints can only be used when datatype is derived from  the set of SPARQL 1.1 Operand Data Types
      l = RDF::Literal("0", datatype: value[:datatype])
      facets.each do |f|
        error(nil, "#{f.first} constraint may only be used once on a numeric datatype (#{value[:datatype]})", production: :litNodeConstraint) if
          f.to_s.match(/digits|inclusive|exclusive/) &&
          !l.is_a?(RDF::Literal::Numeric)
      end

      attrs = [[:datatype, value[:datatype]]] + facets
      Algebra::NodeConstraint.new(*attrs.compact, **self.options)
    end
    start_production(:_litNodeConstraint_3, as_hash: true)
    production(:_litNodeConstraint_3) do |value|
      # valueSet xsFacet*
      facets = value[:_litNodeConstraint_7]
      validate_facets(facets, :litNodeConstraint)
      attrs = value[:valueSet]+ facets
      Algebra::NodeConstraint.new(*attrs.compact, **self.options)
    end
    production(:_litNodeConstraint_4) do |value|
      # numericFacet+
      validate_facets(value, :litNodeConstraint)
      Algebra::NodeConstraint.new(*value, **self.options)
    end

    # [25]    nonLitNodeConstraint  ::= nonLiteralKind stringFacet*
    #                                 | stringFacet+
    start_production(:_nonLitNodeConstraint_1, as_hash: true)
    production(:_nonLitNodeConstraint_1) do |value|
      # nonLiteralKind stringFacet*
      facets = Array(value[:_nonLitNodeConstraint_3])
      validate_facets(facets, :nonLitNodeConstraint)
      attrs = Array(value[:nonLiteralKind]) + facets
      Algebra::NodeConstraint.new(*attrs.compact, **self.options)
    end
    production(:_nonLitNodeConstraint_2) do |value|
      # stringFacet+
      validate_facets(value, :nonLitNodeConstraint)
      Algebra::NodeConstraint.new(*value, **self.options)
    end

    def validate_facets(facets, prod)
      facets.each do |facet|
        if facets.count {|f| f.first == facet.first} > 1
          error(nil, "#{facet.first} constraint may only be used once in a Node Constraint", production: prod)
        end
      end
    end
    private :validate_facets

    # [26]    nonLiteralKind        ::= "IRI" | "BNODE" | "NONLITERAL"
    start_production(:nonLiteralKind, insensitive_strings: :lower)
    production(:nonLiteralKind) do |value|
      value.to_sym
    end

    # [27]    xsFacet               ::= stringFacet | numericFacet
    # [28]    stringFacet           ::= stringLength INTEGER
    #                                 | REGEXP
    production(:stringFacet) do |value|
      if value.is_a?(Array) # stringLength
        value
      else
        unless value =~ %r(^/(.*)/([smix]*)$)
          error(nil, "#{value.inspect} regular expression must be in the form /pattern/flags?", production: :stringFacet)
        end

        flags = $2 unless $2.to_s.empty?
        pattern = $1.gsub('\\/', '/').gsub(UCHAR) do
          [($1 || $2).hex].pack('U*')
        end.force_encoding(Encoding::UTF_8)

        # Any other escaped character is a syntax error
        if pattern.match?(%r([^\\]\\[^nrt/\\|\.?*+\[\]\(\){}$#x2D#x5B#x5D#x5E-]))
          error(nil, "Regexp contains illegal escape: #{pattern.inspect}", production: :stringFacet)
        end

        [:pattern, pattern, flags].compact
      end
    end
    start_production(:_stringFacet_1, as_hash: true)
    production(:_stringFacet_1) do |value|
      [value[:stringLength].to_sym, value[:INTEGER]]
    end

    # [29]    stringLength          ::= "LENGTH" | "MINLENGTH" | "MAXLENGTH"
    start_production(:stringLength, insensitive_strings: :lower)

    # [30]    numericFacet          ::= numericRange numericLiteral
    #                                 | numericLength INTEGER
    start_production(:_numericFacet_1, as_hash: true)
    production(:_numericFacet_1) do |value|
      [value[:numericRange].to_sym, value[:numericLiteral]]
    end
    start_production(:_numericFacet_2, as_hash: true)
    production(:_numericFacet_2) do |value|
      [value[:numericLength].to_sym, value[:INTEGER]]
    end

    # [31]    numericRange          ::= "MININCLUSIVE" | "MINEXCLUSIVE" | "MAXINCLUSIVE" | "MAXEXCLUSIVE"
    start_production(:numericRange, insensitive_strings: :lower)

    # [32]    numericLength         ::= "TOTALDIGITS" | "FRACTIONDIGITS"
    start_production(:numericLength, insensitive_strings: :lower)

    # [33]    shapeDefinition       ::= (includeSet | extraPropertySet | "CLOSED")* '{' tripleExpression? '}' annotation* semanticActions
    start_production(:shapeDefinition, as_hash: true)
    production(:shapeDefinition) do |value|
      shape_definition(
        value[:_shapeDefinition_1],
        value[:_shapeDefinition_2],
        value[:_shapeDefinition_3],
        value[:semanticActions])
    end
    start_production(:_shapeDefinition_4, insensitive_strings: :lower)

    # [34]    inlineShapeDefinition ::= (includeSet | extraPropertySet | "CLOSED")* '{' tripleExpression? '}'
    start_production(:inlineShapeDefinition, as_hash: true)
    production(:inlineShapeDefinition) do |value|
      shape_definition(
        value[:_inlineShapeDefinition_1],
        value[:_inlineShapeDefinition_2])
    end
    def shape_definition(extra_closed, expression, annotations = [], semact = [])
      closed = extra_closed.any? {|v| v.to_s == 'closed'}
      extra = extra_closed.reject  {|v| v.to_s == 'closed'}
      attrs = extra
      attrs << :closed if closed
      attrs << expression if expression
      attrs += annotations
      attrs += semact

      Algebra::Shape.new(*attrs, **self.options)
    end
    private :shape_definition

    # [35]     extraPropertySet       ::= "EXTRA" predicate+
    start_production(:extraPropertySet, insensitive_strings: :lower)
    production(:extraPropertySet) do |value|
      value.last[:_extraPropertySet_1].unshift(:extra)
    end

    # [36]    tripleExpression      ::= oneOfTripleExpr
    production(:tripleExpression) do |value|
      value.first[:oneOfTripleExpr]
    end

    # [37]    oneOfTripleExpr      ::= groupTripleExpr ('|' groupTripleExpr)*
    start_production(:oneOfTripleExpr, as_hash: true)
    production(:oneOfTripleExpr) do |value|
      expressions = [value[:groupTripleExpr]] + value[:_oneOfTripleExpr_1]
      expressions.length == 1 ? expressions.first : Algebra::OneOf.new(*expressions, **self.options)
    end
    production(:_oneOfTripleExpr_2) do |value|
      value.last[:groupTripleExpr]
    end

    # [40]    groupTripleExpr      ::= unaryTripleExpr (';' unaryTripleExpr?)*
    start_production(:groupTripleExpr, as_hash: true)
    production(:groupTripleExpr) do |value|
      expressions = [value[:unaryTripleExpr]] + value[:_groupTripleExpr_1]
      expressions.length == 1 ? expressions.first : Algebra::EachOf.new(*expressions, **self.options)
    end
    production(:_groupTripleExpr_2) do |value|
      value.last[:_groupTripleExpr_3]
    end

    # [43]    unaryTripleExpr            ::= ('$' tripleExprLabel)? (tripleConstraint | bracketedTripleExpr) | include
    start_production(:_unaryTripleExpr_1, as_hash: true)
    production(:_unaryTripleExpr_1) do |value|
      expression = value[:_unaryTripleExpr_3]
      expression.id = value[:_unaryTripleExpr_2] if expression && value[:_unaryTripleExpr_2]

      expression
    end
    production(:_unaryTripleExpr_4) do |value|
      # '$' tripleExprLabel
      value.last[:tripleExprLabel]
    end

    # [44]    bracketedTripleExpr   ::= '(' tripleExpression ')' cardinality? annotation* semanticActions
    start_production(:bracketedTripleExpr, as_hash: true)
    production(:bracketedTripleExpr) do |value|
      case expression = value[:tripleExpression]
      when Algebra::TripleExpression
      else
        error(nil, "Bracketed Expression requires contained triple expression", production: :bracketedTripleExpr)
      end
      cardinality = value[:_bracketedTripleExpr_1] || {}
      attrs = [
        ([:min, cardinality[:min]] if cardinality[:min]),
        ([:max, cardinality[:max]] if cardinality[:max])
      ].compact
      attrs += value[:semanticActions]
      attrs += Array(value[:_bracketedTripleExpr_2])

      expression.operands.concat(attrs)
      expression
    end

    # [45]    tripleConstraint      ::= senseFlags? predicate inlineShapeExpression cardinality? annotation* semanticActions
    start_production(:tripleConstraint, as_hash: true)
    production(:tripleConstraint) do |value|
      cardinality = value[:_tripleConstraint_2] || {}
      attrs = [
        (:inverse if value[:_tripleConstraint_1]),
        [:predicate, value[:predicate]],
        value[:inlineShapeExpression],
        ([:min, cardinality[:min]] if cardinality[:min]),
        ([:max, cardinality[:max]] if cardinality[:max])
      ].compact
      attrs += value[:_tripleConstraint_3]
      attrs += value[:semanticActions]

      Algebra::TripleConstraint.new(*attrs, **self.options) # unless attrs.empty?
    end

    # [46]    cardinality            ::= '*' | '+' | '?' | REPEAT_RANGE
    production(:cardinality) do |value|
      case value
      when '*' then {min: 0, max: "*"}
      when '+' then {min: 1, max: "*"}
      when '?' then {min: 0, max: 1}
      else value
      end
    end

    # [47]    senseFlags             ::= '^'
    # [48]    valueSet              ::= '[' valueSetValue* ']'
    production(:valueSet) do |value|
      value[1][:_valueSet_1]
    end

    # [49]    valueSetValue         ::= iriRange | literalRange | languageRange | '.' exclusion+
    production(:valueSetValue) do |value|
      Algebra::Value.new(value, **self.options)
    end
    production(:_valueSetValue_1) do |value|
      # All exclusions must be consistent IRI/Literal/Language
      value = value.last[:_valueSetValue_2]
      case value.first
      when Algebra::IriStem, RDF::URI
        unless value.all? {|e| e.is_a?(Algebra::IriStem) || e.is_a?(RDF::URI)}
          error(nil, "Exclusions must all be IRI type")
        end
        Algebra::IriStemRange.new(:wildcard, value.unshift(:exclusions), **self.options)
      when Algebra::LiteralStem, RDF::Literal
        unless value.all? {|e| e.is_a?(Algebra::LiteralStem) || e.is_a?(RDF::Literal)}
          error(nil, "Exclusions must all be Literal type")
        end
        Algebra::LiteralStemRange.new(:wildcard, value.unshift(:exclusions), **self.options)
      else
        unless value.all? {|e| e.is_a?(Algebra::LanguageStem) || e.is_a?(String)}
          error(nil, "Exclusions must all be Language type")
        end
        Algebra::LanguageStemRange.new(:wildcard, value.unshift(:exclusions), **self.options)
      end
    end

    # [50]    exclusion             ::= '.' '-' (iri | literal | LANGTAG) '~'?
    start_production(:exclusion, as_hash: true)
    production(:exclusion) do |value|
      if value[:_exclusion_2]
        case value[:_exclusion_1]
        when RDF::URI then Algebra::IriStem.new(value[:_exclusion_1], **self.options)
        when RDF::Literal then Algebra::LiteralStem.new(value[:_exclusion_1], **self.options)
        else Algebra::LanguageStem.new(value[:_exclusion_1], **self.options)
        end
      else
        value[:_exclusion_1]
      end
    end

    # [51]    iriRange              ::= iri ('~' iriExclusion*)?
    production(:iriRange) do |value|
      iri = value.first[:iri]
      if value.last[:_iriRange_1]
        exclusions = value.last[:_iriRange_1].last[:_iriRange_3]
        if exclusions.empty?
          Algebra::IriStem.new(iri, **self.options)
        else
          Algebra::IriStemRange.new(iri, exclusions.unshift(:exclusions), **self.options)
        end
      else
        iri
      end
    end

    # [52]    iriExclusion             ::= '-' iri '~'?
    start_production(:iriExclusion, as_hash: true)
    production(:iriExclusion) do |value|
      value[:_iriExclusion_1] ? Algebra::IriStem.new(value[:iri], **self.options) : value[:iri]
    end

    # [53]    literalRange              ::= literal ('~' literalExclusion*)?
    production(:literalRange) do |value|
      lit = value.first[:literal]
      if value.last[:_literalRange_1]
        exclusions = value.last[:_literalRange_1].last[:_literalRange_3]
        if exclusions.empty?
          Algebra::LiteralStem.new(lit, **self.options)
        else
          Algebra::LiteralStemRange.new(lit, exclusions.unshift(:exclusions), **self.options)
        end
      else
        lit
      end
    end

    # [54]    literalExclusion             ::= '-' literal '~'?
    start_production(:literalExclusion, as_hash: true)
    production(:literalExclusion) do |value|
      val = value[:literal]
      value[:_literalExclusion_1] ? Algebra::LiteralStem.new(val, **self.options) : val
    end

    # [55]    languageRange              ::= LANGTAG ('~' languageExclusion*)?
    #                                      | '@' '~' languageExclusion*
    start_production(:_languageRange_1, as_hash: true)
    production(:_languageRange_1) do |value|
      exclusions = value[:_languageRange_3]  if value[:_languageRange_3]
      pattern = !!value[:_languageRange_3]
      if pattern && exclusions.empty?
        Algebra::LanguageStem.new(value[:LANGTAG], **self.options)
      elsif pattern
        Algebra::LanguageStemRange.new(value[:LANGTAG], exclusions.unshift(:exclusions), **self.options)
      else
        Algebra::Language.new(value[:LANGTAG], **self.options)
      end
    end
    start_production(:_languageRange_2, as_hash: true)
    production(:_languageRange_2) do |value|
      exclusions = value[:_languageRange_6]
      if exclusions.empty?
        Algebra::LanguageStem.new('', **self.options)
      else
        Algebra::LanguageStemRange.new('', exclusions.unshift(:exclusions), **self.options)
      end
    end
    production(:_languageRange_4) do |value|
      value.last[:_languageRange_5]
    end

    # [56]    languageExclusion             ::= '-' LANGTAG '~'?
    start_production(:languageExclusion, as_hash: true)
    production(:languageExclusion) do |value|
      val = value[:LANGTAG]
      value[:_languageExclusion_1] ? Algebra::LanguageStem.new(val, **self.options) : val
    end

    # [57]     include               ::= '&' tripleExprLabel
    production(:include) do |value|
      value.last[:tripleExprLabel]
    end

    # [58]    annotation            ::= '//' predicate (iri | literal)
    start_production(:annotation, as_hash: true)
    production(:annotation) do |value|
      Algebra::Annotation.new([:predicate, value[:predicate]], value[:_annotation_1], **self.options)
    end

    # [59]    semanticActions       ::= codeDecl*

    # [60]    codeDecl              ::= '%' iri (CODE | "%")
    start_production(:codeDecl, as_hash: true)
    production(:codeDecl) do |value|
      code = value[:_codeDecl_1] unless value[:_codeDecl_1] == '%'
      Algebra::SemAct.new(*[value[:iri], code].compact, **self.options)
    end

    # [13t]   literal               ::= rdfLiteral | numericLiteral | booleanLiteral

    # [61]    predicate             ::= iri | RDF_TYPE
    production(:predicate) do |value|
      value
    end

    # [62]    datatype              ::= iri
    production(:datatype) do |value|
      value.first[:iri]
    end

    # [63]    shapeExprLabel        ::= iri | blankNode
    # [16t]   numericLiteral        ::= INTEGER | DECIMAL | DOUBLE
    # [65]  rdfLiteral            ::= langString | string ('^^' datatype)?
    production(:rdfLiteral) do |value|
      literal(*value)
    end
    start_production(:_rdfLiteral_1, as_hash: true)
    production(:_rdfLiteral_1) do |value|
      [value[:string], {datatype: value[:_rdfLiteral_2]}]
    end
    production(:_rdfLiteral_3) do |value|
      value.last[:datatype]
    end

    # [134s]  booleanLiteral        ::= "true" | "false"
    start_production(:booleanLiteral, insensitive_strings: :lower)
    production(:booleanLiteral) do |value|
      literal(value == 'true')
    end

    # [135s]  string                ::= STRING_LITERAL1 | STRING_LITERAL_LONG1
    #                                 | STRING_LITERAL2 | STRING_LITERAL_LONG2
    # [66]   langString            ::= LANG_STRING_LITERAL1 | LANG_STRING_LITERAL_LONG1
    #                                | LANG_STRING_LITERAL2 | LANG_STRING_LITERAL_LONG2
    # [136s]  iri                   ::= IRIREF | prefixedName
    # [1372]  prefixedName          ::= PNAME_LN | PNAME_NS
    production(:prefixedName) do |value|
      value.is_a?(RDF::URI) ? value : ns(value, '')
    end

    # [138s]  blankNode             ::= BLANK_NODE_LABEL
    production(:blankNode) do |value|
      value.first[:BLANK_NODE_LABEL]
    end

    ##
    # Initializes a new parser instance.
    #
    # @example parsing a ShExC schema
    #   schema = ShEx::Parser.new(%(
    #     PREFIX ex: <http://schema.example/> ex:IssueShape {ex:state IRI}
    #   ).parse
    #
    # @param  [String, IO, StringIO, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (for acessing intermediate parser productions)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @option options [#to_s]    :anon_base     ("b0")
    #   Basis for generating anonymous Nodes
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean] :progress
    #   Show progress of parser productions
    # @option options [Boolean] :debug
    #   Detailed debug output
    # @yield  [parser] `self`
    # @yieldparam  [ShEx::Parser] parser
    # @yieldreturn [void] ignored
    # @return [ShEx::Parser]
    # @raise [ShEx::NotSatisfied] if not satisfied
    # @raise [ShEx::ParseError] when a syntax error is detected
    # @raise [ShEx::StructureError, ArgumentError] on structural problems with schema
    def initialize(input = nil, **options, &block)
      @input = case input
      when IO, StringIO then input.read
      else input.to_s.dup
      end
      @input.encode!(Encoding::UTF_8) if @input.respond_to?(:encode!)
      @options = {anon_base: "b0", validate: false}.merge(options)

      debug("base IRI") {base_uri.inspect}
      debug("validate") {validate?.inspect}

      if block_given?
        case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
        end
      end
    end

    # @return [String]
    def to_sxp_bin
      @result
    end

    def to_s
      @result.to_sxp
    end

    alias_method :peg_parse, :parse

    # Parse query
    #
    # The result is a SPARQL Algebra S-List. Productions return an array such as the following:
    #
    #   (prefix ((: <http://example/>))
    #     (union
    #       (bgp (triple ?s ?p ?o))
    #       (graph ?g
    #         (bgp (triple ?s ?p ?o)))))
    #
    # @param [Symbol, #to_s] prod The starting production for the parser.
    #   It may be a URI from the grammar, or a symbol representing the local_name portion of the grammar URI.
    # @return [ShEx::Algebra::Schema] The executable parsed expression.
    # @raise [ShEx::ParseError] when a syntax error is detected
    # @raise [ShEx::StructureError, ArgumentError] on structural problems with schema
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    # @see https://axel.deri.ie/sparqltutorial/ESWC2007_SPARQL_Tutorial_unit2b.pdf
    def parse(prod = :shexDoc)
      @result = peg_parse(@input,
        prod.to_sym,
        ShEx::Meta::RULES,
        whitespace: WS,
        **@options)

      # Validate resulting expression
      @result.validate! if @result && validate?
      @result
    rescue EBNF::PEG::Parser::Error, EBNF::LL1::Lexer::Error =>  e
      raise ShEx::ParseError, e.message, e.backtrace
    end

    private
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
    # Defines the given URI prefixes for this parser.
    #
    # @example
    #   prefixes = {
    #     dc: RDF::URI('http://purl.org/dc/terms/'),
    #   }
    #
    # @param  [Hash{Symbol => RDF::URI}] prefixes
    # @return [Hash{Symbol => RDF::URI}]
    # @since  0.3.0
    def prefixes=(prefixes)
      @options[:prefixes] = prefixes
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
    def prefix(name, iri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      iri.nil? ? prefixes[name] : prefixes[name] = iri
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
    # Returns `true` when resolving IRIs, otherwise BASE and PREFIX are retained in the output algebra.
    #
    # @return [Boolean] `true` or `false`
    # @since  1.0.3
    def validate?
      @options[:validate]
    end

    # Generate a BNode identifier
    def bnode(id)
      RDF::Node.intern(id)
    end

    # Create URIs
    def iri(value)
      # If we have a base URI, use that when constructing a new URI
      value = RDF::URI(value)
      if base_uri && value.relative?
        base_uri.join(value)
      else
        value
      end
    end

    def ns(prefix, suffix)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug {"ns(#{prefix.inspect}): base: '#{base}', suffix: '#{suffix}'"}
      iri(base + suffix.to_s)
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
      RDF::Literal.new(value, **options.merge(validate: validate?))
    end
  end # class Parser
end # module ShEx
