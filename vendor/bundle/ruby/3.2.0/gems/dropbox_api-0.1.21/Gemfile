# frozen_string_literal: true
source 'https://rubygems.org'

gemspec

group :development do
  gem 'bundler', '>= 1.7'
  gem 'rake'

  # Test
  gem 'rspec'
  gem 'vcr'
  gem 'webmock'

  # Gem dependencies
  if RUBY_VERSION >= '2.6'
    gem 'faraday', '~> 2.0'
    gem 'faraday-net_http_persistent'
  else
    gem 'faraday', '~> 1.0'
  end


  # Documentation
  gem 'redcarpet'
  gem 'yard-tests-rspec', git: 'https://github.com/Jesus/yard-spec-plugin.git'

  # Debugging
  gem 'byebug'

  # Code linting
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end
