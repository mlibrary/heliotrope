# frozen_string_literal: true

module EPub
  #
  # Logger
  #
  require 'logger'
  # mattr_accessor :logger
  @logger = Logger.new(STDOUT)

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  #
  # Configure
  #
  @configured = false

  # spec helper
  def self.reset_configured_flag
    @configured = false
  end

  def self.configured?
    @configured
  end

  def self.configure
    @configured = true
    yield self
  end
end

#
# Require Relative
#
require_relative './e_pub/cache'
require_relative './e_pub/cfi'
require_relative './e_pub/cfi_null_object'
require_relative './e_pub/chapter'
require_relative './e_pub/chapter_null_object'
require_relative './e_pub/chapter_presenter'
require_relative './e_pub/paragraph'
require_relative './e_pub/paragraph_null_object'
require_relative './e_pub/paragraph_presenter'
require_relative './e_pub/presenter'
require_relative './e_pub/publication'
require_relative './e_pub/publication_null_object'
require_relative './e_pub/publication_presenter'
require_relative './e_pub/snippet'
require_relative './e_pub/snippet_null_object'
require_relative './e_pub/sql_lite'
require_relative './e_pub/sql_lite_null_object'
require_relative './e_pub/validator'
