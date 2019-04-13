# frozen_string_literal: true

require_relative 'development'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Don't log all the asset requests
  config.assets.quiet = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Web Console is activated in the devproque environment. This is
  # usually a mistake. To ensure it's only activated in development
  # mode, move it to the development group of your Gemfile:
  #
  #   gem 'web-console', group: :development
  #
  # If you still want to run it in the devproque environment (and know
  # what you are doing), put this in your Rails application
  # configuration:
  #
  #   config.web_console.development_only = false
  config.web_console.development_only = false
end
