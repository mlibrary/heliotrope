# Encoding: utf-8

require 'minitest/spec'
require 'minitest/autorun'

require 'scrub_rb'

# Going to require the monkey-patch, which will end up
# monkey-patching String for entire program execution, don't
# know any way to monkey patch just for this test, sorry.

require 'scrub_rb/monkey_patch'

describe "Monkey-patched String#scrub does same thing as ScrubRb.scrub" do
  it "abc\\u304\\x81" do
    "abc\u3042\x81".scrub.must_equal ScrubRb.scrub("abc\u3042\x81")
  end

  it "abc\\u3042\\x81, *" do
    "abc\u3042\x81".scrub("*").must_equal ScrubRb.scrub("abc\u3042\x81", "*")
  end

  it "abc\\u3042\\xE3\\x80 with block" do
    block = lambda do |bytes|
      '<'+bytes.unpack('H*')[0]+'>'
    end

    "abc\u3042\xE3\x80".scrub(&block).must_equal ScrubRb.scrub("abc\u3042\xE3\x80", &block)
  end

  it "no bad bytes" do
    "no bad bytes".scrub.must_equal ScrubRb.scrub("no bad bytes")
  end

end