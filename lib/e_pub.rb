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
# Require Dependencies
#
require 'nokogiri'

#
# Require Relative
#
require_relative './e_pub/bridge_to_webgl'
require_relative './e_pub/cfi'
require_relative './e_pub/chapter'
require_relative './e_pub/marshaller'
require_relative './e_pub/page'
require_relative './e_pub/paragraph'
require_relative './e_pub/publication'
require_relative './e_pub/rendition'
require_relative './e_pub/search'
require_relative './e_pub/section'
require_relative './e_pub/snippet'
require_relative './e_pub/sql_lite'
require_relative './e_pub/toc'
require_relative './e_pub/unmarshaller'
require_relative './e_pub/validator'
