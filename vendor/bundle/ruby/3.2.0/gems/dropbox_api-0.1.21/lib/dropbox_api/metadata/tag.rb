# frozen_string_literal: true
module DropboxApi::Metadata
  class Tag < DropboxApi::Metadata::Base
    def self.new(data)
      case data
      when ::Symbol
        validate(data)
      when Hash
        new(data['.tag'].to_sym)
      when String
        new(data.to_sym)
      else
        raise ArgumentError, "Invalid object for #{name}: #{data.inspect}."
      end
    end

    def self.validate(value)
      if valid_values.include? value
        value
      else
        raise ArgumentError, "Invalid value for #{name}: #{value.inspect}"
      end
    end
  end
end
