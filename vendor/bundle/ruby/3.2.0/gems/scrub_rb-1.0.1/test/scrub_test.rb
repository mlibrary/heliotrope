# Encoding: UTF-8

require 'minitest/spec'
require 'minitest/autorun'

require 'scrub_rb'

describe "ScrubRb" do
  describe "examples from ruby 2.1 String#scrub" do
    it '"abc\u3042\x81".scrub #=> "abc\u3042\uFFFD"' do
      ScrubRb.scrub("abc\u3042\x81").must_equal("abc\u3042\uFFFD")
    end

    it '"abc\u3042\x81".scrub("*") #=> "abc\u3042*"' do
      ScrubRb.scrub("abc\u3042\x81", "*").must_equal("abc\u3042*")
    end

    it 'block' do
      ScrubRb.scrub("abc\u3042\xE3\x80") do |bytes|
        '<'+bytes.unpack('H*')[0]+'>'
      end.must_equal("abc\u3042<e380>")
    end
  end

  # Things investigated in ruby 2.1 String#scrub to make sure
  # we're doing the same things. 
  describe "compatible with ruby 2.1 String#scrub edge cases" do
    it "returns copy even on legal string" do
      original = "perfectly legal"
      scrubbed = ScrubRb.scrub(original)

      # not identity
      refute scrubbed.equal? original
      # yes equality
      assert_equal original, scrubbed
    end
    it "collapses multiple bad bytes into one replacement" do
      ScrubRb.scrub("abc\u3042\xE3\x80").must_equal("abc\u3042\uFFFD")
    end
  end


  before do
    @bad_bytes_utf8   = "M\xE9xico".force_encoding("UTF-8")
    @bad_bytes_utf16  = "M\x00\xDFxico".force_encoding( Encoding::UTF_16LE )
    @bad_bytes_ascii  = "M\xA1xico".force_encoding("ASCII")
  end


  it "replaces with unicode replacement string" do
    scrubbed = ScrubRb.scrub(@bad_bytes_utf8)

    assert scrubbed.valid_encoding?
    assert_equal scrubbed, "M\uFFFDxico"
  end

  it "replaces with chosen replacement string" do
    ScrubRb.scrub(@bad_bytes_utf8, "*").must_equal("M*xico")
  end

  it "preserves encoding with replacement string" do
    input = "good".force_encoding("UTF-8")
    assert_equal input.encoding.name, ScrubRb.scrub(input, "*").encoding.name
    assert_equal input.encoding.name, ScrubRb.scrub(input).encoding.name

    assert_equal "UTF-8", ScrubRb.scrub(@bad_bytes_utf8, "*").encoding.name
    assert_equal "UTF-8", ScrubRb.scrub(@bad_bytes_utf8).encoding.name
  end

  it "replaces with empty string" do
    ScrubRb.scrub(@bad_bytes_utf8, '').must_equal("Mxico")
  end


  it "replaces non-unicode encoding with ? replacement str" do
    if RUBY_PLATFORM == "java"
      skip("known not to pass on JRuby, reported to JRuby github #1361")
    end
    ScrubRb.scrub(@bad_bytes_ascii).must_equal("M?xico")
  end


  it "works with first byte bad" do
    str = "\xE9xico".force_encoding("UTF-8")
    ScrubRb.scrub(str, "?").must_equal("?xico")
  end

  it "works with last bad byte" do
    str = "Mexico\xE9".force_encoding("UTF-8")
    ScrubRb.scrub(str, "?").must_equal("Mexico?")
  end

  it "with works for nil input" do
    ScrubRb.scrub(nil).must_be_nil
  end

end
