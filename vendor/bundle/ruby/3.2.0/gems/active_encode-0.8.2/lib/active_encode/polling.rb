# frozen_string_literal: true
require 'active_support/core_ext/integer/time'
require 'active_model/callbacks'

module ActiveEncode
  module Polling
    extend ActiveSupport::Concern

    POLLING_WAIT_TIME = 10.seconds.freeze

    CALLBACKS = [
      :after_status_update, :after_failed, :after_cancelled, :after_completed
    ].freeze

    included do
      extend ActiveModel::Callbacks

      define_model_callbacks :status_update, :failed, :cancelled, :completed, only: :after

      after_create do |encode|
        ActiveEncode::PollingJob.set(wait: POLLING_WAIT_TIME).perform_later(encode)
      end
    end
  end
end
