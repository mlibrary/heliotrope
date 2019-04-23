# frozen_string_literal: true

require_relative 'testing/source'
require_relative 'testing/target'

require 'yaml'

module Testing
  def self.config
    @config ||= Config.load_from_yaml
  end
  # private_class_method :config

  class Config
    def self.load_from_yaml
      filename = 'testing.yml'
      yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
      return new({}) unless yaml
      new yaml.fetch('testing')
    end

    REQUIRED_KEYS = %w[source_url source_token target_url target_token].freeze

    def initialize(config)
      @config = config
    end

    def valid?
      config_keys = @config.keys
      REQUIRED_KEYS.all? { |required| config_keys.include?(required) }
    end

    REQUIRED_KEYS.each do |key|
      class_eval <<-DEFINE, __FILE__, __LINE__ + 1
        def #{key}
          @config.fetch('#{key}')
        end
      DEFINE
    end
  end
end
