# frozen_string_literal: true

require "pathname"

module Ettin

  # The configuration files for a given root and environment
  class ConfigFiles

    # @param root [String|Pathname]
    # @param env [String]
    # @return [Array<Pathname>]
    def self.for(root:, env:)
      root = Pathname.new(root)
      [
        root/"settings.yml",
        root/"settings"/"#{env}.yml",
        root/"environments"/"#{env}.yml",
        root/"settings.local.yml",
        root/"settings"/"#{env}.local.yml",
        root/"environments"/"#{env}.local.yml"
      ]
    end

  end
end
