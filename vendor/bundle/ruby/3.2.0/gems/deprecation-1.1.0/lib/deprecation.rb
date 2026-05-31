require 'deprecation/behaviors'
require 'deprecation/reporting'
require 'deprecation/method_wrappers'
require 'active_support/concern'
require 'deprecation/core_ext/module/deprecation'
require 'deprecation/rspec'

module Deprecation
  extend ActiveSupport::Concern

  def deprecation_horizon= horizon
    @deprecation_horizon = horizon
  end

  def deprecation_horizon
    @deprecation_horizon
  end

  def silenced
    @silenced
  end

  alias_method :silenced?, :silenced

  def silenced= bool
    @silenced = bool
  end

  def debug
    @debug
  end
  alias_method :debug?, :debug

  def debug= bool
    @debug = bool
  end

  def self.logger
    @logger ||= if defined?(Rails) && Rails.logger
      Rails.logger
    else
      require 'active_support/logger'
      ActiveSupport::Logger.new($stderr)
    end
  end

  def self.logger= value
    @logger = value
  end

  included do
    # By default, warnings are not silenced and debugging is off.
    self.silenced = false
    self.debug = false
  end
end

