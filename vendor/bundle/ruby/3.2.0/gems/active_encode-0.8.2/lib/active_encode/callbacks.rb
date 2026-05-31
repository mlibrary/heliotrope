# frozen_string_literal: true
require 'active_model/callbacks'

module ActiveEncode
  # = Active Encode Callbacks
  #
  # Active Encode provides hooks during the life cycle of an encode. Callbacks allow you
  # to trigger logic during the life cycle of an encode. Available callbacks are:
  #
  # * <tt>after_find</tt>
  # * <tt>after_reload</tt>
  # * <tt>before_create</tt>
  # * <tt>around_create</tt>
  # * <tt>after_create</tt>
  # * <tt>before_cancel</tt>
  # * <tt>around_cancel</tt>
  # * <tt>after_cancel</tt>
  #
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :after_find, :after_reload, :before_create, :around_create,
      :after_create, :before_cancel, :around_cancel, :after_cancel
    ].freeze

    included do
      extend ActiveModel::Callbacks

      define_model_callbacks :find, :reload, only: :after
      define_model_callbacks :create, :cancel
    end
  end
end
