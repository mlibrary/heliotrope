require_relative "types/constants"

module Unicode
  module Types
    def self.types(string)
      res = []
      string.each_char{ |char|
        type_name = type(char)
        res << type_name unless res.include?(type_name)
      }   
      res.sort
    end 
    class << self; alias of types; end 

    def self.type(char)
      require_relative 'types/index' unless defined? ::Unicode::Types::INDEX
      codepoint_depth_offset = get_codepoint_value(char)
      index_or_value = INDEX[:TYPES]
      [0x10000, 0x1000, 0x100, 0x10].each{ |depth|
        index_or_value         = index_or_value[codepoint_depth_offset / depth]
        codepoint_depth_offset = codepoint_depth_offset % depth
        unless index_or_value.is_a? Array
          return INDEX[:TYPE_NAMES][index_or_value.to_i]
        end
      }
      INDEX[:TYPE_NAMES][index_or_value[codepoint_depth_offset].to_i]
    end 

    def self.names
      require_relative 'types/index' unless defined? ::Unicode::Types::INDEX
      INDEX[:TYPE_NAMES].dup
    end

    def self.get_codepoint_value(char)
      ord = nil

      if char.valid_encoding?
        ord = char.ord
      elsif char.encoding.name == "UTF-8"
        begin
          ord = char.unpack("U*")[0]
        rescue ArgumentError
        end
      end

      if ord
        ord
      else
        raise(ArgumentError, "Unicode::Types.type must be given a valid char")
      end
    end

    class << self
      private :get_codepoint_value
    end
  end
end
