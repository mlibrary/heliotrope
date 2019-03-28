# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Contrary to Rails documentation, this is the only way I could set the log levels
# See HELIO-2068
Rails.logger.level = Settings.log_level || 0
Rails.logger.warn("LOG LEVEL IS SET IN environment.rb: #{Rails.logger.level}")
