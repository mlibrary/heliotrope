# frozen_string_literal: true

module PDFEbook
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
require 'origami'

#
# Require Relative
#
require_relative './pdf_ebook/interval'
require_relative './pdf_ebook/publication'
