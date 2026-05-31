# Encoding: utf-8

# Just gives us a ballpark. Some issues with this benchmark:
# * our strings might not be representative of real work
# * we're testing against static class method, not actual monkey patch, which
#   would have one more method call, which may or may not matter.

require 'benchmark'

# for MRI 2.0, let's load the C scrub gem
begin
  require 'string/scrub'
rescue LoadError
  puts "(Could not load scrub gem C backfill)"
end

require 'scrub_rb'

test_strings = [
  "abc\u3042\x81",
  "good string",
  "abc\u3042\xE3\x80",
  "another good string",
  "M\xE9xico",
  "More good string"
]

n = 10000
Benchmark.bmbm do |x|
  x.report("built-in") do
    n.times do
      test_strings.each do |str|
        str.scrub
        str.scrub("*")
        str.scrub {|bytes| '<'+bytes.unpack('H*')[0]+'>'}
      end
    end
  end

  x.report("ScrubRb") do |x|
    n.times do
      test_strings.each do |str|
        ScrubRb.scrub(str)
        ScrubRb.scrub(str, "*")
        ScrubRb.scrub(str) {|bytes| '<'+bytes.unpack('H*')[0]+'>'}
      end
    end
  end
end