# frozen_string_literal: true

require 'noid/rails/version'
require 'noid/rails/config'
require 'noid/rails/engine'
require 'noid/rails/service'
require 'noid/rails/minter'

module Noid
  # A package to integrate Noid identifers with Rails projects
  module Rails
    class << self
      def configure
        yield config
      end

      def config
        @config ||= Config.new
      end

      def treeify(identifier)
        raise ArgumentError, 'Identifier must be a string of size > 0 in order to be treeified' if identifier.blank?
        head = identifier.split('/').first
        head.gsub!(/#.*/, '')
        (head.scan(/..?/).first(4) + [identifier]).join('/')
      end
    end
  end
end
