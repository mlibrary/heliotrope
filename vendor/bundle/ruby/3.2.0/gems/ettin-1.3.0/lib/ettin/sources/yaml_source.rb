# frozen_string_literal: true

require "ettin/source"
require "erb"
require "yaml"

module Ettin
  module Sources

    # Config data from a yaml file
    class YamlSource < Source
      register_default(self)

      def self.handles?(_target)
        true
      end

      def initialize(path)
        @path = path
      end

      def load
        return {} unless File.exist?(path)

        begin
          YAML.safe_load(ERB.new(File.read(path)).result) || {}
        rescue Psych::SyntaxError => e
          raise "YAML syntax error occurred while parsing #{@path}. " \
            "Please note that YAML must be consistently indented using " \
            "spaces. Tabs are not allowed. " \
            "Error: #{e.message}"
        end
      end

      private

      attr_reader :path
    end

  end
end
