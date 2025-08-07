# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require "logger" # fix for rails < 7.1 and concurrent-ruby 1.3.5 https://stackoverflow.com/q/79360526
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
