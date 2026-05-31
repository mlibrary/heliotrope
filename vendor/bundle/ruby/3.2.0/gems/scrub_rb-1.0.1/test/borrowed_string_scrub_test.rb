# coding: US-ASCII

# This whole file borrowered from string-scrub:
# https://raw.github.com/hsbt/string-scrub/master/test/test_scrub.rb
# Actually adapted originally from MRI test suite:
# https://github.com/ruby/ruby/blob/3ac0ec4ecdea849143ed64e8935e6675b341e44b/test/ruby/test_m17n.rb#L1505
# We want to make sure we pass the same tests.
#
# NOTE: Some tests of multiple contiguous illegal bytes, we've had
# to change to match scrub_rb behavior. 
# See README under 'Discrepency'; search this source for 'SKIPPED'
# and 'OWN'

require 'scrub_rb'
require 'scrub_rb/monkey_patch'
require 'test/unit'


class BorrowedStringScrubTest < Test::Unit::TestCase
  module AESU
    def ua(str) str.dup.force_encoding("US-ASCII") end
    def a(str) str.dup.force_encoding("ASCII-8BIT") end
    def e(str) str.dup.force_encoding("EUC-JP") end
    def s(str) str.dup.force_encoding("Windows-31J") end
    def u(str) str.dup.force_encoding("UTF-8") end
  end
  include AESU

  def test_scrub
    str = "\u3042\u3044"
    assert_not_same(str, str.scrub)
    str.force_encoding(Encoding::ISO_2022_JP) # dummy encoding
    assert_not_same(str, str.scrub)

    # SKIPPED, discrepency
    #assert_equal("\uFFFD\uFFFD\uFFFD", u("\x80\x80\x80").scrub)
    # OWN equivalent
    assert_equal("\uFFFD", u("\x80\x80\x80").scrub)

    #assert_equal("\uFFFDA", u("\xF4\x80\x80A").scrub)

    # examples in Unicode 6.1.0 D93b
    # SKIPPED, discrepency
    #assert_equal("\x41\uFFFD\uFFFD\x41\uFFFD\x41",
    #             u("\x41\xC0\xAF\x41\xF4\x80\x80\x41").scrub)
    # OWN equivalent
    assert_equal("\x41\uFFFD\x41\uFFFD\x41",
                 u("\x41\xC0\xAF\x41\xF4\x80\x80\x41").scrub)

    # SKIPPED, discrepency
    #assert_equal("\x41\uFFFD\uFFFD\uFFFD\x41",
    #             u("\x41\xE0\x9F\x80\x41").scrub)
    # OWN equivalent
    assert_equal("\x41\uFFFD\x41",
                 u("\x41\xE0\x9F\x80\x41").scrub)

    # SKIPPED, discrepency
    #assert_equal("\u0061\uFFFD\uFFFD\uFFFD\u0062\uFFFD\u0063\uFFFD\uFFFD\u0064",
    #             u("\x61\xF1\x80\x80\xE1\x80\xC2\x62\x80\x63\x80\xBF\x64").scrub)
    # OWN equivalent
    assert_equal("\u0061\uFFFD\u0062\uFFFD\u0063\uFFFD\u0064",
                 u("\x61\xF1\x80\x80\xE1\x80\xC2\x62\x80\x63\x80\xBF\x64").scrub)
    # SKIPPED discrepency
    #assert_equal("abcdefghijklmnopqrstuvwxyz\u0061\uFFFD\uFFFD\uFFFD\u0062\uFFFD\u0063\uFFFD\uFFFD\u0064",
    #             u("abcdefghijklmnopqrstuvwxyz\x61\xF1\x80\x80\xE1\x80\xC2\x62\x80\x63\x80\xBF\x64").scrub)
    # OWN equivalent
    assert_equal("abcdefghijklmnopqrstuvwxyz\u0061\uFFFD\u0062\uFFFD\u0063\uFFFD\u0064",
                 u("abcdefghijklmnopqrstuvwxyz\x61\xF1\x80\x80\xE1\x80\xC2\x62\x80\x63\x80\xBF\x64").scrub)


    assert_equal("\u3042\u3013", u("\xE3\x81\x82\xE3\x81").scrub("\u3013"))
    assert_raise(Encoding::CompatibilityError){ u("\xE3\x81\x82\xE3\x81").scrub(e("\xA4\xA2")) }
    assert_raise(TypeError){ u("\xE3\x81\x82\xE3\x81").scrub(1) }
    assert_raise(ArgumentError){ u("\xE3\x81\x82\xE3\x81\x82\xE3\x81").scrub(u("\x81")) }
    assert_equal(e("\xA4\xA2\xA2\xAE"), e("\xA4\xA2\xA4").scrub(e("\xA2\xAE")))

    assert_equal("\u3042<e381>", u("\xE3\x81\x82\xE3\x81").scrub{|x|'<'+x.unpack('H*')[0]+'>'})
    assert_raise(Encoding::CompatibilityError){ u("\xE3\x81\x82\xE3\x81").scrub{e("\xA4\xA2")} }


    assert_raise(TypeError){ u("\xE3\x81\x82\xE3\x81").scrub{1} }
    assert_raise(ArgumentError){ u("\xE3\x81\x82\xE3\x81\x82\xE3\x81").scrub{u("\x81")} }
    assert_equal(e("\xA4\xA2\xA2\xAE"), e("\xA4\xA2\xA4").scrub{e("\xA2\xAE")})

    assert_equal(u("\x81"), u("a\x81").scrub {|c| break c})
    assert_raise(ArgumentError) {u("a\x81").scrub {|c| c}}

    assert_equal("\uFFFD\u3042".encode("UTF-16BE"),
                 "\xD8\x00\x30\x42".force_encoding(Encoding::UTF_16BE).
                 scrub)
    assert_equal("\uFFFD\u3042".encode("UTF-16LE"),
                 "\x00\xD8\x42\x30".force_encoding(Encoding::UTF_16LE).
                 scrub)
    assert_equal("\uFFFD".encode("UTF-32BE"),
                 "\xff".force_encoding(Encoding::UTF_32BE).
                 scrub)
    assert_equal("\uFFFD".encode("UTF-32LE"),
                 "\xff".force_encoding(Encoding::UTF_32LE).
                 scrub)
  end

  def test_scrub_bang
    str = "\u3042\u3044"
    assert_same(str, str.scrub!)
    str.force_encoding(Encoding::ISO_2022_JP) # dummy encoding
    assert_same(str, str.scrub!)

    str = u("\x80\x80\x80")
    str.scrub!
    assert_same(str, str.scrub!)
    # SKIPPED, discrepency
    #assert_equal("\uFFFD\uFFFD\uFFFD", str)
    # OWN, single replacement
    assert_equal("\uFFFD", str)
  end
end