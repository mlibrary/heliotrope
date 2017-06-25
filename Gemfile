# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

##############################################################################
#
# Rails
#
##############################################################################

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.1'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

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

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

##############################################################################
#
# Hyrax
#
##############################################################################

gem 'hyrax', github: 'samvera/hyrax', ref: '72b5992e9a38fa18d5d325181a031d0d09eab196' # Jun 23, 2017

group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

# gem 'rsolr', '>= 1.0'
gem 'devise'
gem 'devise-guests', '~> 0.6'
gem 'jquery-rails' # Use jquery as the JavaScript library
group :development, :test do
  gem 'fcrepo_wrapper'
  gem 'rspec-rails'
end

##############################################################################
#
# Heliotrope
#
##############################################################################

gem 'actionpack-page_caching', '~> 1.1.0'
gem 'carrierwave', '~> 1.1.0'
gem 'config' # use config gem to pull in settings from .yml files
gem 'cozy-sun-bear', git: 'https://github.com/mlibrary/cozy-sun-bear', ref: '068659c7740dbe9c270c0824d922efb8295142c4'
gem 'httparty'
gem 'jekyll', '~> 3.1.3'
gem 'jquery-turbolinks'
gem 'legato', '~> 0.3'
gem 'oauth'
gem 'oauth2', '~> 1.2'
gem 'redcarpet', '~> 3.3.4'
gem 'resque', '~> 1.26.0'
gem 'resque-pool'
gem 'resque-web', '~> 0.0.7', require: 'resque_web'
gem 'riiif', '0.4.0'
gem 'rsolr', '~> 2.0.1'
gem 'rubyzip'
gem 'signet'
gem 'uglifier', '>= 3.2.0'

group :development do
  gem 'pry-rails', '~> 0.3.4'
  gem 'sdoc', '~> 0.4.0', group: :doc # bundle exec rake doc:rails generates the API under doc/api.
end

group :development, :test do
  gem 'rubocop', '~> 0.48.1'
  gem 'rubocop-rspec', '~> 1.15.1'
  gem 'sqlite3' # Use sqlite3 as the database for Active Record
end

group :test do
  gem 'coveralls', require: false
  gem 'factory_girl_rails'
  gem "fakefs", require: "fakefs/safe"
  gem 'rails-controller-testing'
  gem 'rspec-context-private'
  gem 'rspec-html-matchers'
end

group :production do
  gem 'clamav'
  gem 'mysql2' # Use mysql2 as the database for Active Record
end
