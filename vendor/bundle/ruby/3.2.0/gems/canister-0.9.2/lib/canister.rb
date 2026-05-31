# frozen_string_literal: true

require "canister/version"

# A container that registers keys to values that are
# resolved at runtime. This allows for out-of-order declaration,
# automatic dependency resolution, and--upon
# redeclaration--automatic dependency cache invalidation.
class Canister

  def initialize
    @stack = []
    @registry = {}
    @resolved = {}
    @dependents = Hash.new do |hash, key|
      hash[key] = []
    end
    @mutex = Mutex.new
    yield self if block_given?
  end

  # We override method_missing to enable dot notation
  # for accessing registered values.
  def method_missing(method, *args, &block)
    if handles?(method)
      resolve(method)
    else
      super(method, *args, block)
    end
  end

  # We override respond_to? to enable dot notation
  # for accessing registered values.
  def respond_to_missing?(method, include_all = false)
    handles?(method) || super(method, include_all)
  end

  def synchronize(&block)
    if @mutex.owned?
      yield
    else
      @mutex.synchronize(&block)
    end
  end

  # Register a value to a key by passing a block. Note that
  # the value will be that returned by the block. If the key
  # has been registered before, the old registration is
  # overwritten. Dependents of the original registration
  # are automatically invalidated.
  # @param key [Symbol]
  # @yield self [Container] Yields this container.
  # @return the value defined in the block
  def register(key, &block)
    key = key.to_sym
    synchronize do
      invalidate(key) if registered?(key)
      registry[key] = block
    end
    self
  end

  # Recursively resolves the object that was registered to
  # the key. This value is memoized.
  # @param key [Symbol]
  def resolve(key)
    key = key.to_sym
    value = nil
    synchronize do
      add_dependent(key)
      stack << key
      value = resolved[key] ||= registry[key].call(self)
      stack.pop
    end
    value
  end
  alias_method :[], :resolve

  def keys
    registry.keys
  end

  private

  attr_reader :dependents, :registry, :resolved, :stack

  def handles?(method)
    registered?(method)
  end

  def add_dependent(key)
    unless stack.empty?
      dependents[key] << stack.last
    end
  end

  def registered?(key)
    registry.key?(key)
  end

  def unresolve(key)
    resolved.delete(key)
  end

  def invalidate(key, first = true)
    unresolve(key)
    dependents[key]
      .each {|child| invalidate(child, false) }
    if first
      dependents.delete(key)
    end
  end

end
