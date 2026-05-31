# frozen_string_literal: true

module Noid
  module Rails
    # Configuration parameters for creating identifiers
    class Config
      attr_writer :template, :statefile, :namespace, :minter_class, :identifier_in_use

      def template
        @template ||= '.reeddeeddk'
      end

      def statefile
        @statefile ||= '/tmp/minter-state'
      end

      def namespace
        @namespace ||= 'default'
      end

      def minter_class
        @minter_class ||= Minter::File
      end

      # A check to guarantee the identifier is not already in use. When true,
      # the minter will continue to cycle through ids until it finds one that
      # returns false
      def identifier_in_use
        @identifier_in_use ||= lambda do |_id|
          false
        end
      end
    end
  end
end
