# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

def coverage_needed?
  ENV['COVERAGE'] || ENV['TRAVIS']
end

if coverage_needed?
  require 'simplecov'
  require 'coveralls'
  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  )
  SimpleCov.start('rails') do
    add_filter '/.internal_test_app'
    add_filter '/lib/generators'
    add_filter '/spec'
    add_filter '/lib/noid/rails/version.rb'
  end
  SimpleCov.command_name 'spec'
end

require 'engine_cart'
EngineCart.load_application!

require 'noid-rails'
require 'byebug' unless ENV['CI']

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.filter_run_when_matching :focus
end
