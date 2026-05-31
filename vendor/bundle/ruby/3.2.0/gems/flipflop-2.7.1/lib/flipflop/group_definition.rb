module Flipflop
  class GroupDefinition
    attr_reader :key, :name, :title

    def initialize(key)
      @key = key
      @name = @key.to_s.freeze
      @title = @name.humanize.freeze
    end
  end
end
