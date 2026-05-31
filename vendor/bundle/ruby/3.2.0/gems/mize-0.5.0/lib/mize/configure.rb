module Mize::Configure
  attr_accessor :default_cache

  def cache(cache)
    self.default_cache = cache
  end

  def configure(&block)
    instance_eval(&block)
  end
end

module Mize
  extend Mize::Configure
end

Mize.default_cache = Mize::DefaultCache.new
