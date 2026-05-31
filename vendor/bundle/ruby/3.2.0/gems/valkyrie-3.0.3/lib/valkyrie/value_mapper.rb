# frozen_string_literal: true
module Valkyrie
  ##
  # ValueMapper is a way to handle coordinating extendable casting of values
  # depending on what the value is. It's used in many of the adapters in
  # Valkyrie.
  #
  # Typically a root node is defined as a sub-class ValueMapper to separate
  # value mappers for a distinct purpose, but it's not a requirement.
  #
  # @example Defining a ValueMapper which converts symbols to strings.
  #   class ParentMapper < ValueMapper
  #   end
  #   class Stringify < ValueMapper
  #     ParentMapper.register(self)
  #     def self.handles?(value)
  #       value.kind_of?(Symbol)
  #     end
  #     def result
  #       value.to_s
  #     end
  #   end
  # @example Use a ValueMapper
  #   ParentMapper.for(:symbol).result # => "symbol"
  class ValueMapper
    # Register a value caster.
    # @param value_caster [Valkyrie::ValueMapper]
    def self.register(value_caster)
      self.value_casters += [value_caster]
    end

    # @return [Array<Valkyrie::ValueMapper>] Registered value casters.
    def self.value_casters
      @value_casters ||= []
    end

    class << self
      attr_writer :value_casters
    end

    # Find the value caster for a given value.
    # @param value [Anything] The value to find a caster for.
    def self.for(value)
      (value_casters + [self]).find do |value_caster|
        value_caster.handles?(value)
      end.new(value, self)
    end

    # Test whether this caster handles a given value.
    # @param value [Anything]
    # @return [Boolean]
    def self.handles?(_value)
      true
    end

    attr_reader :value, :calling_mapper
    def initialize(value, calling_mapper)
      @value = value
      @calling_mapper = calling_mapper
    end

    # @return Casted value.
    def result
      value
    end
  end
end
