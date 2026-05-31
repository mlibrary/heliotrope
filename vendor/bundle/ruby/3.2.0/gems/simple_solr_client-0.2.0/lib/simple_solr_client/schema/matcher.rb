# Figure out how to match a field name to a copyfield/dynamicfield
class SimpleSolrClient::Schema
  module Matcher
    def derive_matcher(src)
      if src =~ /\A\*(.*)/
        Regexp.new("\\A(.*)(#{Regexp.escape($1)})\\Z")
      else
        src
      end
    end

    def matches(s)
      @matcher === s
    end
  end
end
