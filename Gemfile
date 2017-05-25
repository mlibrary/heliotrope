# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
# gem 'rails', '4.2.6'
# gem 'rails', '4.2.7.1'
gem 'rails', '5.0.2'

# gem 'curation_concerns', '2.0.0'
# gem 'hyrax', github: 'projecthydra-labs/hyrax', ref: '9395ac75a04902237bf692c0b67c9cf292c9d39d' # May 18th
gem 'hyrax', '1.0.1'

gem 'resque', '~> 1.26.0'
gem 'resque-pool'
gem 'resque-web', '~> 0.0.7', require: 'resque_web'

# We need this due to #778.
# gem 'active-fedora', '~> 11.1.5', github: 'projecthydra/active_fedora', ref: 'fae7df019337506b53fc721b22414fdc45830f9b'
gem 'active-fedora', '~> 11.1.6'

# clamav only in production
gem 'clamav', group: :production

# gem 'pg', '0.18.4'
gem 'mysql2'
gem 'puma'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# use config gem to pull in settings from .yml files
gem 'config'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 3.2.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# jQuery plugin for drop-in fix binded events problem caused by Turbolinks
gem 'jquery-turbolinks'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'riiif', '0.4.0'

gem 'actionpack-page_caching', '~> 1.1.0'

gem 'redcarpet', '~> 3.3.4'

# Use Jekyll for blog and informational pages
# See #937 before updating this version
gem 'jekyll', '~> 3.1.3'

# Use gem version of cozy-sun-bear
gem 'cozy-sun-bear', git: 'https://github.com/mlibrary/cozy-sun-bear', ref: '86064869129ecbf3b614590ba325e2e2a0b9ccd0'

# Talking to Google Analytics
gem 'legato', '~> 0.3'
gem 'oauth'
gem 'oauth2', '~> 1.2'
gem 'signet'

# test coverage with coveralls
gem 'coveralls', require: false

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'httparty'
gem 'rubyzip'

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'pry-rails', '~> 0.3.4'
  gem 'spring'
end

gem 'devise'
gem 'devise-guests', '~> 0.3'
# gem 'rsolr', '~> 1.1.2'
gem 'rsolr', '~> 2.0.1'

group :development, :test do
  gem 'byebug'
  gem 'capybara'
  gem 'factory_girl_rails'
  gem "fakefs", require: "fakefs/safe"
  gem 'fcrepo_wrapper', '0.5.2'
  gem 'rails-controller-testing'
  gem 'rspec-context-private'
  gem 'rspec-html-matchers'
  gem 'rspec-rails'
  gem 'rubocop', '~> 0.48.1'
  gem 'rubocop-rspec', '~> 1.15.1'
  gem 'solr_wrapper', '0.21.0'
  gem 'sqlite3'
end
