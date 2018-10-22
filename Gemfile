# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.3'
gem 'rails-html-sanitizer', '~> 1.0.4'

# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Pinning Rack commit that resolves the large file upload issue
# When 2.0.4 is out this might not be needed anymore
gem 'rack', git: 'https://github.com/rack/rack.git', ref: 'ee01748'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'chromedriver-helper'
  gem 'selenium-webdriver'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

##############################################################################
#
# Heliotriope
#
##############################################################################

gem 'actionpack-page_caching', '~> 1.1.0'

# gem 'active-fedora', '~> 11.3.1'

# Canister provides containers
gem 'canister', '~> 0.9.0'

gem 'carrierwave', '~> 1.1.0'

# Checkpoint provides authorization support
gem 'checkpoint', '~> 1.0.3'
# gem 'checkpoint', git: 'https://github.com/mlibrary/checkpoint', branch: 'master'

# clamav only in production
gem 'clamav', group: :production

# use config gem to pull in settings from .yml files
gem 'config'

# Use gem version of cozy-sun-bear
gem 'cozy-sun-bear', git: 'https://github.com/mlibrary/cozy-sun-bear', ref: '7fc0608c307bbeb8cd09e52050f178ff651250be'

gem 'devise'
gem 'devise-guests', '~> 0.3'

gem 'faraday', '~>0.12.2'
gem 'faraday_middleware', '~>0.12.2'

gem 'hyrax', '2.0.0'

# Use Jekyll for blog and informational pages
gem 'jekyll', '~> 3.6.3'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# jQuery plugin for drop-in fix binded events problem caused by Turbolinks
gem 'jquery-turbolinks'

# Json Web Token
gem 'jwt'

# Keycard provides authentication support and user/request information
gem 'keycard', '~> 0.2.4'
# gem 'keycard', git: 'https://github.com/mlibrary/keycard', branch: 'master'

# Use MySQL as the database for Active Record
gem 'mysql2', '~> 0.4.10'

# Force epub search results to be sentences
gem 'pragmatic_segmenter', '~> 0.3'

# Turn page image epub chapters into pdfs
gem 'prawn', '~> 2.2'

gem 'redcarpet', '~> 3.3.4'

gem 'resque', '~> 1.26.0'
gem 'resque-pool'
gem 'resque-web', '~> 0.0.7', require: 'resque_web'

gem 'riiif', '1.4.1'

gem 'rsolr', '~> 2.0.1'

# Use Zip to extract EPubs
gem 'rubyzip', '~> 1.2.2'

gem 'sitemap_generator', '~> 6.0.1'

gem 'sinatra', '~> 2.0.2'
# CVE-2018-3760
gem 'sprockets', '~> 3.7.2'

# sqlite for epub indexing
gem 'sqlite3'

# SwaggerClient - the Ruby gem for the COUNTER_SUSHI5_0 API
gem 'swagger_client', git: 'https://github.com/mlibrary/swagger_client', branch: 'master'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 3.2.0'

# Talking to Google Analytics
gem 'legato', '~> 0.3'
gem 'oauth'
gem 'oauth2', '~> 1.2'
gem 'signet'

# performance profiling
gem 'skylight'

group :development, :test do
  gem 'byebug'
  # test coverage with coveralls
  gem 'coveralls', require: false
  gem 'factory_bot_rails'
  gem "fakefs", require: "fakefs/safe"
  gem "faker"
  gem 'fcrepo_wrapper', '0.5.2'
  gem 'rails-controller-testing'
  gem 'rspec-context-private'
  gem 'rspec-html-matchers'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'ruumba', '0.1.2'
  gem 'solr_wrapper', '0.21.0'
end

group :development do
  gem 'pry-rails', '~> 0.3.4'
  # Yay! A Ruby Documentation Tool
  gem 'yard'
end
