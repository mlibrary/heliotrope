# encoding: utf-8
module RDF::N3
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
    U_CHARS2         = Regexp.compile("\\u00B7|[\\u0300-\\u036F]|[\\u203F-\\u2040]", Regexp::FIXEDENCODING).freeze
    IRI_RANGE        = Regexp.compile("[[^<>\"{}|^`\\\\]&&[^\\x00-\\x20]]", Regexp::FIXEDENCODING).freeze

    ESCAPE_CHAR4        = /\\u(?:[0-9A-Fa-f]{4,4})/u.freeze    # \uXXXX
    ESCAPE_CHAR8        = /\\U(?:[0-9A-Fa-f]{8,8})/u.freeze    # \UXXXXXXXX
    UCHAR               = /#{ESCAPE_CHAR4}|#{ESCAPE_CHAR8}/n.freeze
    # 170s
    PERCENT              = /%[0-9A-Fa-f]{2}/u.freeze
    # 172s
    PN_LOCAL_ESC         = /\\[_~\.\-\!$\&'\(\)\*\+,;=\/\?\#@%]/u.freeze
    # 169s
    PLX                  = /#{PERCENT}|#{PN_LOCAL_ESC}/u.freeze
    # 163s
    PN_CHARS_BASE        = /[A-Z]|[a-z]|#{U_CHARS1}/u.freeze
    # 164s
    PN_CHARS_U           = /_|#{PN_CHARS_BASE}/u.freeze
    # 166s
    PN_CHARS             = /-|[0-9]|#{PN_CHARS_U}|#{U_CHARS2}/u.freeze
    PN_LOCAL_BODY        = /(?:(?:\.|:|#{PN_CHARS}|#{PLX})*(?:#{PN_CHARS}|:|#{PLX}))?/u.freeze
    PN_CHARS_BODY        = /(?:(?:\.|#{PN_CHARS})*#{PN_CHARS})?/u.freeze
    # 167s
    PN_PREFIX            = /#{PN_CHARS_BASE}#{PN_CHARS_BODY}/u.freeze
    # 168s
    PN_LOCAL             = /(?:[0-9]|:|#{PN_CHARS_U}|#{PLX})#{PN_LOCAL_BODY}/u.freeze
    # 154s
    EXPONENT             = /[eE][+-]?[0-9]+/u.freeze
    # 159s
    ECHAR                = /\\[tbnrf\\"']/u.freeze
    # 18
    IRIREF               = /<(?:#{IRI_RANGE}|#{UCHAR})*>/mu.freeze
    # 139s
    PNAME_NS             = /#{PN_PREFIX}?:/u.freeze
    # 140s
    PNAME_LN             = /#{PNAME_NS}#{PN_LOCAL}/u.freeze
    # 141s
    BLANK_NODE_LABEL     = /_:(?:[0-9]|#{PN_CHARS_U})(?:(?:#{PN_CHARS}|\.)*#{PN_CHARS})?/u.freeze
    # 144s
    # XXX: negative-lookahed for @is and @has
    LANGTAG              = /@(?!(?:is|has))(?:[a-zA-Z]+(?:-[a-zA-Z0-9]+)*)/u.freeze
    # 19
    INTEGER              = /[+-]?[0-9]+/u.freeze
    # 20
    DECIMAL              = /[+-]?(?:[0-9]*\.[0-9]+)/u.freeze
    # 21
    DOUBLE               = /[+-]?(?:[0-9]+\.[0-9]*#{EXPONENT}|\.?[0-9]+#{EXPONENT})/u.freeze
    # 22
    STRING_LITERAL_SINGLE_QUOTE      = /'(?:[^\'\\\n\r]|#{ECHAR}|#{UCHAR})*'/u.freeze
    # 23
    STRING_LITERAL_QUOTE             = /"(?:[^\"\\\n\r]|#{ECHAR}|#{UCHAR})*"/u.freeze
    # 24
    STRING_LITERAL_LONG_SINGLE_QUOTE = /'''(?:(?:'|'')?(?:[^'\\]|#{ECHAR}|#{UCHAR}))*'''/um.freeze
    # 25
    STRING_LITERAL_LONG_QUOTE        = /"""(?:(?:"|"")?(?:[^"\\]|#{ECHAR}|#{UCHAR}))*"""/um.freeze

    # 28t
    PREFIX               = /@?prefix/ui.freeze
    # 29t
    BASE                 = /@?base/ui.freeze
    QUICK_VAR_NAME       = /\?#{PN_LOCAL}/.freeze

    # 161s
    WS                   = /(?:\s|(?:#[^\n\r]*))+/um.freeze
    # 162s
    ANON                 = /\[\s*\]/u.freeze
  end
end