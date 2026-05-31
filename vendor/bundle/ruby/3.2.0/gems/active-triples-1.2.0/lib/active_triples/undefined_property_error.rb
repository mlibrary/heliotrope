# frozen_string_literal: true
module ActiveTriples
  ##
  # An error class to be raised when attempting to reflect on an undefined 
  # property.
  #
  # @example
  #   begin 
  #     my_source.set_value(:fake_property, 'blah')
  #   rescue ActiveTriples::UndefinedPropertyError => e
  #     e.property => 'fake_property'
  #     e.klass => 'MySourceClass'
  #   end
  #   
  class UndefinedPropertyError < ArgumentError
    attr_reader :property, :klass

    def initialize(property, klass)
      @property = property
      @klass = klass
    end

    def message
      "The property `#{@property}` is not defined on class '#{@klass}'"
    end
  end
end
