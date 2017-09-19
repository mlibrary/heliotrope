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
  # noid validator
  #
  def self.noid?(id)
    return false if id.nil?
    return false if id.blank?
    return false unless id.is_a?(String)
    return false if (id =~ /^[[:alnum:]]{9}$/).nil?
    true
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
# Dependencies
#
Dir.glob('./**/lib/e_pub/**/*').each do |file|
  require_dependency file if File.file?(file)
end
