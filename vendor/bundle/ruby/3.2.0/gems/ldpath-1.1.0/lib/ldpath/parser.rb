require 'parslet'

module Ldpath
  class Parser < Parslet::Parser
    root :doc
    rule(:doc) { prologue? >> statements? >> eof }

    rule(:prologue) { wsp? >> directive?.repeat(1, 1) >> (eol >> wsp? >> directive >> wsp?).repeat >> wsp? >> eol? }
    rule(:prologue?) { prologue.maybe }
    rule(:directive) { prefixID | graph | filter | boost }
    rule(:directive?) { directive.maybe }

    rule(:statements) { wsp? >> statement?.repeat(1, 1) >> (eol >> wsp? >> statement >> wsp?).repeat >> wsp? >> eol? }
    rule(:statements?) { statements.maybe }
    rule(:statement) { mapping }
    rule(:statement?) { mapping.maybe }

    # whitespace rules
    rule(:eol) { (str("\n") >> str("\r").maybe).repeat(1) }
    rule(:eol?) { eol.maybe }
    rule(:eof) { any.absent? }
    rule(:space) { str("\n").absent? >> match('\s').repeat(1) }
    rule(:space?) { space.maybe }
    rule(:wsp) { (space | multiline_comment | single_line_comment).repeat(1) }
    rule(:wsp?) { wsp.maybe }
    rule(:multiline_comment) { (str("/*") >> (str("*/").absent? >> any).repeat >> str("*/")) }
    rule(:single_line_comment) { str("#") >> (eol.absent? >> any).repeat }

    # simple types
    rule(:integer) { match("[+-]").maybe >> match("\\d").repeat(1) }
    rule(:decimal) { match("[+-]").maybe >> match("\\d").repeat >> str(".") >> match("\\d").repeat(1) }
    rule(:double) do
      match("[+-]").maybe >> (
        (match("\\d").repeat(1) >> str('.') >> match("\\d").repeat >> exponent) |
        (str('.') >> match("\\d").repeat(1) >> exponent) |
        (match("\\d").repeat(1) >> exponent)
      )
    end

    rule(:exponent) { match('[Ee]') >> match("[+-]").maybe >> match("\\d").repeat(1) }
    rule(:numeric_literal) { integer.as(:integer) | decimal.as(:decimal) | double.as(:double) }
    rule(:boolean_literal) { str('true').as(:true) | str('false').as(:false) }

    rule(:string) { string_literal_quote | string_literal_single_quote | string_literal_long_single_quote | string_literal_long_quote }

    rule(:string_literal_quote) do
      str('"') >> (match("[^\\\"\\\\\\r\\n]") | echar | uchar).repeat.as(:string) >> str('"')
    end

    rule(:string_literal_single_quote) do
      str("'") >> (match("[^'\\\\\\r\\n]") | echar | uchar).repeat.as(:string) >> str("'")
    end

    rule(:string_literal_long_quote) do
      str('"""') >> (str('"""').absent? >> match("[^\\\\]") | echar | uchar).repeat.as(:string) >> str('"""')
    end

    rule(:string_literal_long_single_quote) do
      str("'''") >> (str("'''").absent? >> match("[^\\\\]") | echar | uchar).repeat.as(:string) >> str("'''")
    end

    # operators
    rule(:self_op) { str(".") }
    rule(:and_op) { str("&") }
    rule(:or_op) { str("|") }
    rule(:p_sep) { str("/") }
    rule(:plus) { str("+") }
    rule(:star) { str("*") }
    rule(:not_op) { str("!") }
    rule(:inverse) { str("^") }
    rule(:question) { str("?") }
    rule(:is) { str "is" }
    rule(:is_a) { str "is-a" }
    rule(:func) { str "fn:" }
    rule(:type) { str "^^" }
    rule(:lang) { str "@" }
    rule(:loose) { str("~") }

    # strings
    rule(:comma) { str(",") }
    rule(:scolon) { str(";") }
    rule(:colon) { str(":") }
    rule(:dcolon) { str("::") }
    rule(:assign) { str("=") }
    rule(:k_prefix) { str("@prefix") }
    rule(:k_graph) { str("@graph") }
    rule(:k_filter) { str("@filter") }
    rule(:k_boost) { str("@boost") }

    # iris
    rule(:iri) do
      iriref |
        prefixed_name
    end

    rule(:iriref) do
      str("<") >> (match("[^[[:cntrl:]]<>\"{}|^`\\\\]") | uchar).repeat.as(:iri) >> str('>')
    end

    rule(:uchar) do
      str('\u') >> hex.repeat(4, 4) | hex.repeat(6, 6)
    end

    rule(:echar) do
      str('\\') >> match("[tbnrf\"'\\\\]")
    end

    rule(:hex) do
      match("[[:xdigit:]]")
    end

    rule(:prefixed_name) do
      (identifier.as(:prefix) >> str(":") >> identifier.as(:localName)).as(:iri)
    end

    rule(:identifier) { pn_chars_base >> (str(".").maybe >> pn_chars).repeat }

    rule(:pn_chars_base) do
      match("[A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\u{10000}-\u{EFFFF}]")
    end

    rule(:pn_chars) do
      pn_chars_base | match("[0-9\u00B7\u0300-\u036F\u203F-\u2040_-]")
    end

    # "xyz"; 0.123e52; true
    rule(:literal) do
      (
        rdf_literal |
          numeric_literal |
          boolean_literal
      ).as(:literal)
    end

    # "xyz"; "xyz"^^a; "xyz"@en
    rule(:rdf_literal) do
      string >> lang >> identifier.as(:lang) |
        string >> type >> iri.as(:type) |
        string
    end

    rule(:node) do
      iri | literal
    end

    # @prefix id = iri ;
    rule(:prefixID) do
      (
      k_prefix >> wsp? >>
      (identifier | str("")).as(:id) >> wsp? >>
      colon >> wsp? >>
      iriref >> space? >> scolon.maybe
      ).as(:prefixID)
    end

    # @graph iri, iri, iri ;
    rule(:graph) do
      k_graph >> wsp? >>
        iri_list.as(:graphs) >> wsp? >> scolon
    end

    # <info:a>, <info:b>
    rule(:iri_list) do
      iri.as(:iri) >>
        (
          wsp? >>
          comma >> wsp? >>
          iri_list.as(:rest)
        ).repeat
    end

    # @filter test ;
    rule(:filter) do
      (k_filter >> wsp? >> node_test.as(:test) >> wsp? >> scolon).as(:filter)
    end

    # @boost selector ;
    rule(:boost) do
      (k_boost >> wsp? >> selector.as(:selector) >> wsp? >> scolon).as(:boost)
    end

    # id = . ;
    rule(:mapping) do
      (
        label.as(:name) >> wsp? >>
        assign >> wsp? >>
        selector.as(:selector) >>
        (wsp? >>
          dcolon >> wsp? >> field_type
        ).maybe >> wsp? >> scolon
      ).as(:mapping)
    end

    rule(:label) do
      iri | identifier
    end

    # xsd:string
    rule(:field_type) do
      iri.as(:field_type) >> field_type_options.maybe
    end

    # ( x = "xyz", y = "abc" )
    rule(:field_type_options) do
      group(field_type_option >> (wsp? >> comma >> wsp? >> field_type_option).repeat).as(:options)
    end

    # x = "xyz"
    rule(:field_type_option) do
      identifier.as(:key) >> wsp? >> assign >> wsp? >> literal.as(:value)
    end

    # selector groups
    rule(:selector) do
      (
        compound_or_path_selector |
        testing_selector |
        atomic_selector
      )
    end

    # &; |
    rule(:compound_operator) { and_op | or_op }

    # a & b; a | b; a / b
    rule(:compound_or_path_selector) do
      path_selector | compound_selector
    end

    # a & b; a | b
    rule(:compound_selector) do
      atomic_or_testing_or_path_selector.as(:left) >> wsp? >>
        compound_operator.as(:op) >> wsp? >>
        selector.as(:right)
    end

    # a / b
    rule(:path_selector) do
      atomic_or_testing_selector.as(:left) >> wsp? >>
        p_sep.as(:op) >> wsp? >>
        atomic_or_testing_or_path_selector.as(:right)
    end

    # info:a[is-a z]
    rule(:testing_selector) do
      atomic_selector.as(:delegate) >>
        str("[") >> wsp? >>
        node_test.as(:test) >> wsp? >>
        str("]")
    end

    rule(:atomic_selector) do
      (
        self_selector |
        function_selector |
        property_selector |
        loose_property_selector |
        wildcard_selector |
        reverse_property_selector |
        literal_selector |
        recursive_path_selector |
        grouped_selector |
        tap_selector |
        not_property_selector
      )
    end

    rule(:atomic_or_testing_selector) do
      (testing_selector | atomic_selector)
    end

    rule(:atomic_or_testing_or_path_selector) do
      (path_selector | atomic_or_testing_selector)
    end

    # Atomic Selectors
    rule(:self_selector) do
      self_op.as(:self)
    end

    # fn:x() or fn:x(1,2,3)
    rule(:function_selector) do
      function_without_args | function_with_arglist
    end

    rule(:function_without_args) do
      func >> identifier.as(:fname) >> group(wsp?)
    end

    rule(:function_with_arglist) do
      func >> identifier.as(:fname) >> group(arglist.as(:arglist))
    end

    rule(:arglist) do
      selector >>
        (
          wsp? >>
          comma >> wsp? >>
          selector
        ).repeat
    end

    # xyz
    rule(:loose_property_selector) do
      loose.as(:loose) >>
        wsp? >>
        iri.as(:property)
    end

    # xyz
    rule(:property_selector) do
      iri.as(:property)
    end

    # *
    rule(:wildcard_selector) do
      star.as(:wildcard)
    end

    # ^xyz
    rule(:reverse_property_selector) do
      inverse.as(:reverse) >> iri.as(:property)
    end

    rule(:not_property_selector) do
      not_one_property_selector
    end

    rule(:not_one_property_selector) do
      not_op.as(:not) >> iri.repeat(1, 1).as(:property)
    end

    rule(:literal_selector) do
      literal.as(:literal)
    end

    # (x)?; (x)*; (x)+; (x){3,5}
    rule(:recursive_path_selector) do
      group(selector.as(:delegate)) >>
        range.as(:repeat)
    end

    # ?; *; +; {3,5}; {,5}; {3,}
    rule(:range) do
      (
        star |
        plus |
        question |
        str("{") >> wsp? >> integer.as(:min).maybe >> wsp? >> str(",") >> wsp? >> integer.as(:max).maybe >> wsp? >> str("}")
      ).as(:range)
    end

    # (<info:a>)
    rule(:grouped_selector) do
      group(selector)
    end

    # ?<a>(<info:a>)
    rule(:tap_selector) do
      question >>
        str("<") >> wsp? >>
        (str(">").absent? >> any).repeat(1).as(:identifier) >> wsp? >>
        str(">") >> wsp? >>
        atomic_selector.as(:tap)
    end

    # Testing Selectors

    rule(:node_test) do
      grouped_test |
        not_test |
        compound_test |
        atomic_node_test
    end

    rule(:atomic_node_test) do
      literal_language_test |
        literal_type_test |
        is_a_test |
        path_equality_test |
        function_test |
        path_test
    end

    rule(:grouped_test) do
      group(node_test)
    end

    rule(:not_test) do
      not_op.as(:not) >> node_test.as(:delegate)
    end

    rule(:compound_test) do
      atomic_node_test.as(:left_test) >> wsp? >>
        compound_operator.as(:op) >> wsp? >>
        node_test.as(:right_test)
    end

    # @en
    rule(:literal_language_test) do
      lang >> identifier.as(:lang)
    end

    # ^^xyz
    rule(:literal_type_test) do
      type >> iri.as(:type)
    end

    rule(:is_a_test) do
      (
        is_a >> wsp? >>
        node.as(:right)
      ).as(:is_a)
    end

    rule(:path_equality_test) do
      (
        selector >> wsp? >>
        is >> wsp? >>
        node.as(:right)
      ).as(:is)
    end

    rule(:function_test) do
      function_without_args | function_with_arglist
    end

    rule(:path_test) do
      (
        path_selector |
        testing_selector |
        atomic_selector
      )
    end

    def group(atom)
      str("(") >> wsp? >>
        atom >> wsp? >>
        str(")")
    end
  end
end
