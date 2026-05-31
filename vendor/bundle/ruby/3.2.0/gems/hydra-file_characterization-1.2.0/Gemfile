# frozen_string_literal: true
source 'https://rubygems.org'

# Specify your gem's dependencies in hydra/file_characterization.gemspec
gemspec

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end
