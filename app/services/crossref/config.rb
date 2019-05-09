# frozen_string_literal: true

module Crossref
  module Config
    def self.load_config
      filename = Rails.root.join('config', 'crossref.yml')
      yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
      unless yaml
        Rails.logger.error("Unable to fetch any keys from #{filename}.")
        return {}
      end
      yaml.fetch("crossref")
    end
  end
end
