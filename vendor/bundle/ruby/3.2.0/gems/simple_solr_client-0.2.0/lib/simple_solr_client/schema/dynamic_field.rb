require 'simple_solr_client/schema/field'
class SimpleSolrClient::Schema
  class DynamicField < Field

    def initialize(*args)
      super
      @dynamic = true
    end

    def xml_node(doc)
      Nokogiri::XML::Element.new('dynamicField', doc)
    end

    # What name will we get from a matching thing?
    def dynamic_name(s)
      m = @matcher.match(s)
      if m
        m[1] << m[2]
      end
    end

  end
end
