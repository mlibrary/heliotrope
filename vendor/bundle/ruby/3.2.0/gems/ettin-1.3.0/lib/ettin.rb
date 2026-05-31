# frozen_string_literal: true

require "ettin/version"
require "ettin/options"
require "ettin/hash_factory"
require "ettin/config_files"

# Ettin is the best way to add settings to
# any ruby project.
module Ettin
  def self.settings_files(root, env)
    ConfigFiles.for(root: root, env: env)
  end

  def self.for(*targets)
    Options.new(HashFactory.new.build(targets))
  end
end
