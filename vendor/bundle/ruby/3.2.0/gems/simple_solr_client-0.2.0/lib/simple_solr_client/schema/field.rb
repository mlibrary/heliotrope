require 'simple_solr_client/schema/field_or_type'
class SimpleSolrClient::Schema
  class Field < Field_or_Type
    include Matcher

    attr_accessor :type_name, :type
    attr_reader :matcher


    def initialize(*args)
      super
      @dynamic = false
    end

    # We'll defer to the field type when calling any of the attribute
    # methods
    ([TEXT_ATTR_MAP.keys, BOOL_ATTR_MAP.keys].flatten - [:type_name]).each do |x|
      define_method(x) do
        rv = super()
        if rv.nil?
          self.type[x]
        else
          rv
        end
      end
    end



        # We can only resolve the actual type in the presence of a
    # particular schema
    def resolve_type(schema)
      self.type = schema.field_type(self.type_name)
      self
    end


    # When we reset the name, make sure to re-derive the matcher
    # object
    def name=(n)
      @name    = n
      @matcher = derive_matcher(n)
    end

  end
end
