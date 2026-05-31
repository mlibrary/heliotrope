# frozen_string_literal: true

module Ettin

  # Generic interface for data sources containing configuration information.
  class Source
    def self.for(target)
      registry.find {|candidate| candidate.handles?(target) }
        .new(target)
    end

    def self.registry
      @@registry ||= [] # rubocop:disable Style/ClassVars
    end

    def self.register(candidate)
      registry.unshift(candidate)
    end

    def self.register_default(candidate)
      registry << candidate
    end

    def load
      raise NotImplementedError
    end

  end
end

Dir["#{File.dirname(__FILE__)}/sources/**/*.rb"].each {|f| require f }
