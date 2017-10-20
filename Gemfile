# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.3'
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

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
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

gem 'active-fedora', '~> 11.3.1'

gem 'carrierwave', '~> 1.1.0'

# clamav only in production
gem 'clamav', group: :production

# use config gem to pull in settings from .yml files
gem 'config'

# Use gem version of cozy-sun-bear
gem 'cozy-sun-bear', git: 'https://github.com/mlibrary/cozy-sun-bear', ref: '8a86f04ff8b546edd3d50f2da1061e17f3edb8fb'

gem 'devise'
gem 'devise-guests', '~> 0.3'

gem 'httparty'

# gem 'hyrax', '1.0.4'
gem 'hyrax', '2.0.0.rc1'

# Use Jekyll for blog and informational pages
# See #937 before updating this version
gem 'jekyll', '~> 3.1.3'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# jQuery plugin for drop-in fix binded events problem caused by Turbolinks
gem 'jquery-turbolinks'

# Use MySQL as the database for Active Record
gem 'mysql2'

gem 'redcarpet', '~> 3.3.4'

gem 'resque', '~> 1.26.0'
gem 'resque-pool'
gem 'resque-web', '~> 0.0.7', require: 'resque_web'

gem 'riiif', '1.4.1'

gem 'rsolr', '~> 2.0.1'

# Use Zip to extract EPubs
gem 'rubyzip'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'sitemap_generator'

# sqlite for epub indexing
gem 'sqlite3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 3.2.0'

# Talking to Google Analytics
gem 'legato', '~> 0.3'
gem 'oauth'
gem 'oauth2', '~> 1.2'
gem 'signet'

group :development, :test do
  gem 'byebug'
  # test coverage with coveralls
  gem 'coveralls', require: false
  gem 'factory_girl_rails'
  gem "fakefs", require: "fakefs/safe"
  gem 'fcrepo_wrapper', '0.5.2'
  gem 'rails-controller-testing'
  gem 'rspec-context-private'
  gem 'rspec-html-matchers'
  gem 'rspec-rails'
  gem 'rubocop', '~> 0.49.1'
  gem 'rubocop-rspec', '~> 1.15.1'
  gem 'ruumba'
  gem 'solr_wrapper', '0.21.0'
end

group :development do
  gem 'pry-rails', '~> 0.3.4'
end
