# -*- encoding: utf-8 -*-
require 'ebnf/ll1/lexer'

module ShEx
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

    # 87
    UCHAR4               = /\\u([0-9A-Fa-f]{4,4})/.freeze
    UCHAR8               = /\\U([0-9A-Fa-f]{8,8})/.freeze
    UCHAR                = Regexp.union(UCHAR4, UCHAR8).freeze
    # 171s
    PERCENT              = /%\h\h/.freeze
    # 173s
    PN_LOCAL_ESC         = /\\[_~\.\-\!$\&'\(\)\*\+,;=\/\?\#@%]/.freeze
    # 170s
    PLX                  = /#{PERCENT}|#{PN_LOCAL_ESC}/.freeze.freeze
    # 164s
    PN_CHARS_BASE        = /[A-Za-z]|#{U_CHARS1}/.freeze
    # 165s
    PN_CHARS_U           = /_|#{PN_CHARS_BASE}/.freeze
    # 167s
    PN_CHARS             = /[\d-]|#{PN_CHARS_U}|#{U_CHARS2}/.freeze
    PN_LOCAL_BODY        = /(?:(?:\.|:|#{PN_CHARS}|#{PLX})*(?:#{PN_CHARS}|:|#{PLX}))?/.freeze
    PN_CHARS_BODY        = /(?:(?:\.|#{PN_CHARS})*#{PN_CHARS})?/.freeze
    # 168s
    PN_PREFIX            = /#{PN_CHARS_BASE}#{PN_CHARS_BODY}/.freeze
    # 169s
    PN_LOCAL             = /(?:[\d|]|#{PN_CHARS_U}|#{PLX})#{PN_LOCAL_BODY}/.freeze
    # 155s
    EXPONENT             = /[eE][+-]?\d+/
    # 160s
    ECHAR                = /\\[tbnrf\\"']/

    WS                   = %r((
                              \s
                            | (?:\#[^\n\r]*)
                            | (?:/\*(?:(?:\*[^/])|[^*])*\*/)
                            )+)xmu.freeze

    # 69
    RDF_TYPE             = /a/.freeze
    # 18t
    IRIREF               = /<(?:#{IRI_RANGE}|#{UCHAR})*>/.freeze
    # 73
    PNAME_NS             = /#{PN_PREFIX}?:/.freeze
    # 74
    PNAME_LN             = /#{PNAME_NS}#{PN_LOCAL}/.freeze
    # 75
    ATPNAME_NS           = /@#{WS}*#{PN_PREFIX}?:/m.freeze
    # 76
    ATPNAME_LN           = /@#{WS}*#{PNAME_NS}#{PN_LOCAL}/m.freeze
    # 77
    BLANK_NODE_LABEL     = /_:(?:\d|#{PN_CHARS_U})(?:(?:#{PN_CHARS}|\.)*#{PN_CHARS})?/.freeze
    # 78
    LANGTAG              = /@[a-zA-Z]+(?:-[a-zA-Z0-9]+)*/.freeze
    # 79
    INTEGER              = /[+-]?\d+/.freeze
    # 80
    DECIMAL              = /[+-]?(?:\d*\.\d+)/.freeze
    # 81
    DOUBLE               = /[+-]?(?:\d+\.\d*#{EXPONENT}|\.?\d+#{EXPONENT})/.freeze
    # 83
    STRING_LITERAL1      = /'(?:[^\'\\\n\r]|#{ECHAR}|#{UCHAR})*'/.freeze
    # 84
    STRING_LITERAL2      = /"(?:[^\"\\\n\r]|#{ECHAR}|#{UCHAR})*"/.freeze
    # 85
    STRING_LITERAL_LONG1 = /'''(?:(?:'|'')?(?:[^'\\]|#{ECHAR}|#{UCHAR}))*'''/m.freeze
    # 86
    STRING_LITERAL_LONG2 = /"""(?:(?:"|"")?(?:[^"\\]|#{ECHAR}|#{UCHAR}))*"""/m.freeze

    # 83l
    LANG_STRING_LITERAL1      = /'(?:[^\'\\\n\r]|#{ECHAR}|#{UCHAR})*'#{LANGTAG}/.freeze
    # 84l
    LANG_STRING_LITERAL2      = /"(?:[^\"\\\n\r]|#{ECHAR}|#{UCHAR})*"#{LANGTAG}/.freeze
    # 85l
    LANG_STRING_LITERAL_LONG1 = /'''(?:(?:'|'')?(?:[^'\\]|#{ECHAR}|#{UCHAR}))*'''#{LANGTAG}/m.freeze
    # 86l
    LANG_STRING_LITERAL_LONG2 = /"""(?:(?:"|"")?(?:[^"\\]|#{ECHAR}|#{UCHAR}))*"""#{LANGTAG}/m.freeze

    # XX
    REGEXP              =  %r(/(?:[^/\\\n\r]|\\[nrt\\|.?*+(){}$-\[\]^/]|#{UCHAR})+/[smix]*).freeze

    # 68
    CODE                 = /\{(?:[^%\\]|\\[%\\]|#{UCHAR})*%#{WS}*\}/m.freeze
    # 70
    REPEAT_RANGE         = /\{\s*#{INTEGER}(?:,#{WS}*(?:#{INTEGER}|\*)?)?#{WS}*\}/.freeze
  
  end
end
