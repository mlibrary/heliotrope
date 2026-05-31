# frozen_string_literal: true

require 'rails'
require 'cancan'
require 'blacklight'
require 'blacklight/access_controls'

module Blacklight::AccessControls
  extend ActiveSupport::Autoload

  class << self
    def configure
      @config ||= Config.new
      yield @config if block_given?
      @config
    end
    alias config configure
  end

  # This error is raised when a user isn't allowed to access a given controller action.
  # This usually happens within a call to Enforcement#enforce_access_controls but can be
  # raised manually.
  class AccessDenied < ::CanCan::AccessDenied; end
end
