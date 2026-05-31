# frozen_string_literal: true

require "deep_merge/rails_compat"
require "forwardable"
require "ettin/method_name"

module Ettin

  # An object that holds configuration settings / options
  class Options
    include Enumerable
    extend Forwardable

    def_delegators :@hash, :keys, :empty?

    def initialize(hash)
      @hash = hash
      @hash.deep_transform_keys! {|key| key.to_s.to_sym }
      @hash.default = nil
    end

    def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissingSuper
      return super(method, *args, &block) unless handles?(method)

      method = MethodName.new(method)
      if method.bang?
        handle_bang_method(method)
      elsif method.assignment?
        handle_assignment_method(method, *args)
      else
        self[method.clean]
      end
    end

    # We respond to:
    # * all methods our parents respond to
    # * all methods that are mostly alpha-numeric: /^[a-zA-Z_0-9]*$/
    # * all methods that are mostly alpha-numeric + !: /^[a-zA-Z_0-9]*\!$/
    def respond_to_missing?(method, include_all = false)
      handles?(method) || super(method, include_all)
    end

    def key?(key)
      hash.key?(convert_key(key))
    end
    alias_method :has_key?, :key?

    def merge(other)
      new_hash = {}
        .deeper_merge(hash)
        .deeper_merge!(other.to_h, overwrite_arrays: true)
      self.class.new(new_hash)
    end

    def merge!(other)
      hash.deeper_merge!(other.to_h, overwrite_arrays: true)
      self
    end

    def [](key)
      convert(hash[convert_key(key)])
    end

    def []=(key, value)
      hash[convert_key(key)] = value
    end

    def to_h
      hash
    end
    alias_method :to_hash, :to_h

    def eql?(other)
      to_h == other.to_h
    end
    alias_method :==, :eql?

    def each
      hash.each {|k, v| yield k, convert(v) }
    end

    private

    attr_reader :hash

    def handle_bang_method(method)
      if key?(method.clean)
        self[method.clean]
      else
        raise KeyError, "key #{method.clean} not found"
      end
    end

    def handle_assignment_method(method, *args)
      self[method.clean] = args.first
    end

    def handles?(method)
      /^[a-zA-Z_0-9]*(\!|=)?$/.match(method.to_s)
    end

    def convert_key(key)
      key.to_s.to_sym
    end

    def convert(value)
      case value
      when Hash
        Options.new(value)
      when Array
        value.map {|i| convert(i) }
      else
        value
      end
    end
  end

end
