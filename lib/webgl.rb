# frozen_string_literal: true

module Webgl
  require 'logger'

  @logger = Logger.new(STDOUT)

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end
end

require_relative './webgl/unity'
require_relative './webgl/unity_validator'
