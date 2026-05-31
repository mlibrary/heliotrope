# frozen_string_literal: true
module DropboxApi::Metadata
  class Field
    def initialize(type, options = [])
      @type = type
      @options = options
    end

    def cast(object)
      if object.nil?
        raise ArgumentError unless @options.include? :optional
        nil
      else
        force_cast object
      end
    end

    def force_cast(object)
      if @type == String
        object.to_s
      elsif @type == Time
        Time.parse(object)
      elsif @type == Integer
        object.to_i
      elsif @type == Float
        object.to_f
      elsif @type == Symbol
        object['.tag'].to_sym
      elsif @type == :boolean
        object.to_s == 'true'
      elsif @type.ancestors.include?(DropboxApi::Metadata::Base) ||
            @type.ancestors.include?(Array) ||
            @type == DropboxApi::Metadata::Resource
        @type.new(object)
      else
        raise NotImplementedError, "Can't cast #{object} to `#{@type}`"
      end
    end
  end
end
