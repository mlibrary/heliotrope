# frozen_string_literal: true

require "ettin/options"
require "ettin/source"

module Ettin
  module Sources

    # Config data from an Ettin::Options
    class OptionsSource < Source
      register(self)

      def self.handles?(target)
        target.is_a? Options
      end

      def initialize(options)
        @hash = options.to_h
      end

      def load
        hash
      end

      private

      attr_reader :hash
    end

  end
end
