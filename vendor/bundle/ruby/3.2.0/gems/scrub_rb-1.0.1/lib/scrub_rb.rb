require "scrub_rb/version"
require 'scrub_rb/monkey_patch'

module ScrubRb

  # static function implementation of String#scrub, where
  # first arg is the string.
  #
  #     ScrubRb.scrub("abc\u3042\x81") #=> "abc\u3042\uFFFD"
  #     ScrubRb.scrub("abc\u3042\x81", "*") #=> "abc\u3042*"
  #     ScrubRb.scrub("abc\u3042\xE3\x80") {|bytes| '<'+bytes.unpack('H*')[0]+'>' } #=> "abc\u3042<e380>"
  def self.scrub(str, replacement=nil, &block)
    return str if str.nil?

    if replacement.nil? && ! block_given?
      replacement =
         # UTF-8 for unicode replacement char \uFFFD, encode in
         # encoding of input string, using '?' as a fallback where
         # it can't be (which should be non-unicode encodings)
         "\xEF\xBF\xBD".force_encoding("UTF-8").encode( str.encoding,
                                                  :undef => :replace,
                                                  :replace => '?' )  
    end

    result          = "".force_encoding("BINARY")
    bad_chars       = "".force_encoding("BINARY")
    bad_char_flag   = false # weirdly, optimization to use flag

    str.chars.each do |c|
      if c.valid_encoding?
        if bad_char_flag
          scrub_replace(result, bad_chars, replacement, block)
          bad_char_flag = false
        end
        result << c
      else
        bad_char_flag = true
        bad_chars << c
      end
    end
    if bad_char_flag
      scrub_replace(result, bad_chars, replacement, block)
    end

    result.force_encoding(str.encoding)

    return result
  end

  private
  def self.scrub_replace(result, bad_chars, replacement, block)
    if block
      r = block.call(bad_chars)
    else
      r = replacement
    end

    if r.respond_to?(:to_str)
      r = r.to_str
    else
      raise TypeError, "no implicit conversion of #{r.class} into String"
    end

    unless r.valid_encoding?
      raise ArgumentError,  "replacement must be valid byte sequence '#{replacement}'"
    end

    result << r
    bad_chars.clear
  end

end
