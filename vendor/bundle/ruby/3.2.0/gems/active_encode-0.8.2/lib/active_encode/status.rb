# frozen_string_literal: true
require 'active_support'

module ActiveEncode
  module Status
    extend ActiveSupport::Concern

    included do
      # Current state of the encoding process
      attr_accessor :state
      attr_accessor :errors

      attr_accessor :created_at
      attr_accessor :updated_at
    end

    def cancelled?
      state == :cancelled
    end

    def completed?
      state == :completed
    end

    def running?
      state == :running
    end

    def failed?
      state == :failed
    end
  end
end
