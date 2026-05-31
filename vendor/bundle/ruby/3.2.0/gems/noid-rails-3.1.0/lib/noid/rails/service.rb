# frozen_string_literal: true

require 'noid'

module Noid
  module Rails
    # A service that validates and mints identifiers
    class Service
      attr_reader :minter

      def initialize(minter = default_minter)
        @minter = minter
      end

      delegate :valid?, to: :minter

      delegate :mint, to: :minter

      protected

      def default_minter
        Noid::Rails.config.minter_class.new
      end
    end
  end
end
