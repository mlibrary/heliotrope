module Flipflop
  class FeatureDefinition
    attr_reader :key, :name, :title, :description, :default, :group, :location

    def initialize(key, **options)
      @key = key
      @name = @key.to_s.freeze
      @title = options.delete(:title).freeze || @name.humanize.freeze
      @description = options.delete(:description).freeze
      @default = !!options.delete(:default) || false
      @group = options.delete(:group).freeze
      @location = caller_locations(3, 1).first.freeze

      if options.any?
        raise FeatureError.new(name, "has unknown option #{options.keys.map(&:inspect) * ', '}")
      end
    end
  end
end
