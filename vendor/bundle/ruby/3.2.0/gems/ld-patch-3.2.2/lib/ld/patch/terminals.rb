require 'ebnf/ll1/lexer'

module LD::Patch
  module Terminals
    # Definitions of token regular expressions used for lexical analysis
  
    ##
    # Unicode regular expressions for Ruby 1.9+ with the Oniguruma engine.
    U_CHARS1         = Regexp.compile(<<-EOS.gsub(/\s+/, ''))
                         [\\u00C0-\\u00D6]|[\\u00D8-\\u00F6]|[\\u00F8-\\u02FF]|
                         [\\u0370-\\u037D]|[\\u037F-\\u1FFF]|[\\u200C-\\u200D]|
                         [\\u2070-\\u218F]|[\\u2C00-\\u2FEF]|[\\u3001-\\uD7FF]|
                         [\\uF900-\\uFDCF]|[\\uFDF0-\\uFFFD]|[\\u{10000}-\\u{EFFFF}]
                       EOS
    U_CHARS2         = Regexp.compile("\\u00B7|[\\u0300-\\u036F]|[\\u203F-\\u2040]").freeze
    IRI_RANGE        = Regexp.compile("[[^<>\"{}|^`\\\\]&&[^\\x00-\\x20]]").freeze

    # 26
    UCHAR                = EBNF::LL1::Lexer::UCHAR
    # 159s
    ECHAR                = /\\[tbnrf\\"']/.freeze

    # 18
    IRIREF               = /<(?:#{IRI_RANGE}|#{UCHAR})*>/.freeze
    # 144s
    LANGTAG              = /@[a-zA-Z]+(?:-[a-zA-Z0-9]+)*/.freeze
    # 154s
    EXPONENT             = /[eE][+-]?[0-9]+/
    # 19
    INTEGER              = /[+-]?[0-9]+/.freeze
    # 20
    DECIMAL              = /[+-]?(?:[0-9]*\.[0-9]+)/.freeze
    # 21
    DOUBLE               = /[+-]?(?:[0-9]+\.[0-9]*#{EXPONENT}|\.?[0-9]+#{EXPONENT})/.freeze
    # 22
    STRING_LITERAL_QUOTE      = /"([^\"\\\n\r]|#{ECHAR}|#{UCHAR})*"/.freeze
    # 23
    STRING_LITERAL_SINGLE_QUOTE      = /'([^\'\\\n\r]|#{ECHAR}|#{UCHAR})*'/.freeze
    # 24
    STRING_LITERAL_LONG_SINGLE_QUOTE = /'''((?:'|'')?(?:[^'\\]|#{ECHAR}|#{UCHAR}))*'''/m.freeze
    # 25
    STRING_LITERAL_LONG_QUOTE = /"""((?:"|"")?(?:[^"\\]|#{ECHAR}|#{UCHAR}))*"""/m.freeze
    # 161s
    WS                   = /(?:\s|(?:#[^\n\r]*))+/m.freeze
    # 162s
    ANON                 = /\[#{WS}*\]/m.freeze
    # 170s
    PERCENT              = /%[0-9A-Fa-f]{2}/.freeze

    # 172s
    PN_LOCAL_ESC         = /\\[_~\.\-\!$\&'\(\)\*\+,;=:\/\?\#@%]/.freeze
    # 163s
    PN_CHARS_BASE        = /[A-Z]|[a-z]|#{U_CHARS1}/.freeze
    # 164s
    PN_CHARS_U           = /_|#{PN_CHARS_BASE}/.freeze
    # 166s
    PN_CHARS             = /-|[0-9]|#{PN_CHARS_U}|#{U_CHARS2}/.freeze
    # 169s
    PLX                  = /#{PERCENT}|#{PN_LOCAL_ESC}/.freeze

    # 141s
    BLANK_NODE_LABEL     = /_:(?:[0-9]|#{PN_CHARS_U})((#{PN_CHARS}|\.)*#{PN_CHARS})?/.freeze
    # 166s
    VARNAME              = /(?:[0-9]|#{PN_CHARS_U})
                            (?:[0-9]|#{PN_CHARS_U}|#{U_CHARS2})*/x.freeze
    # 143s
    VAR1                 = /\?#{VARNAME}/.freeze
    # 167s
    PN_CHARS_BODY        = /(?:(?:\.|#{PN_CHARS})*#{PN_CHARS})?/.freeze
    PN_PREFIX            = /#{PN_CHARS_BASE}#{PN_CHARS_BODY}/.freeze
    # 168s
    PN_LOCAL_BODY        = /(?:(?:\.|:|#{PN_CHARS}|#{PLX})*(?:#{PN_CHARS}|:|#{PLX}))?/.freeze
    PN_LOCAL             = /(?:[0-9]|:|#{PN_CHARS_U}|#{PLX})#{PN_LOCAL_BODY}/.freeze
    # 139s
    PNAME_NS             = /#{PN_PREFIX}?:/.freeze
    # 1402
    PNAME_LN             = /(?:#{PNAME_NS})(?:#{PN_LOCAL})/.freeze

    # String terminals, case sensitive
    STR_EXPR = %r(AddNew|AN|Add
                 |Bind
                 |Cut
                 |DeleteExisting|Delete|DE
                 |UpdateList|UL
                 |@prefix
                 |true|false
                 |\^\^|\.\.
                 |[\(\),.;\[\]\{\}\=!^\/aABCD]
              )x.freeze
  end
end