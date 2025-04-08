# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'railties', '> 3', '< 7'
gem 'rails', '~> 6.0.5'

gem 'rails-html-sanitizer'

# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 5.6.9'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0'
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'
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

gem 'rack', '> 1', '< 3'

# HELIO-2404 APTRUST PRESERVATION
gem 'bagit'
gem 'minitar', '~>0.8'
gem 'aws-sdk-s3', '~> 1'
gem 'typhoeus', '~> 1.1'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  # This is picky, fiddly stuff requiring rails/capybara/etc versions to be in sync
  gem 'capybara', '~> 3.29'
  gem 'webdrivers', '~> 5.0'
end

group :development do
  gem 'listen', '>=3.0.5', '<4.0'
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
# Heliotrope
#
##############################################################################

gem 'blacklight_oai_provider', "~> 7.0.2"

# HELIO-2531
# gem "sassc", ">= 2.0.0"
# gem "bootstrap-sass", ">= 3.4.1"

# A rails 5.2 thing. Might make startup faster. Not sure if it really matters though.
# I guess we'll see.
# https://github.com/Shopify/bootsnap
# gem 'bootsnap', '~> 1.4.6'
gem 'bootsnap', '~> 1.18'

# This is installed via yarn instead for heliotrope so it's in package.json
# But there's *something* in the stack that needs it here.
# I suspect it's related to resque-web
gem 'bootstrap', '~> 4.0'

# Canister provides containers
gem 'canister', '~> 0.9.0'

gem 'carrierwave', '~> 1.3.2'

# Checkpoint provides authorization support
gem 'checkpoint', '~> 1.1.0'

# clamav only in production
gem 'clamby', group: :production

# use config gem to pull in settings from .yml files
gem 'config'

gem 'devise', '>= 4.7.1'
gem 'devise-guests', '~> 0.7'

# Bundler could not find compatible versions for gem "faraday":
#   In Gemfile:
#     faraday (~> 2)
#
#     hyrax (= 2.9.5) was resolved to 2.9.5, which depends on
#       signet was resolved to 0.12.0, which depends on
#         faraday (~> 0.9)
gem 'faraday', '~> 1.0'
# NOTE: This is the last minor release in the v0.x series, next release will be 1.0 to match Faraday v1.0 release and from then on only fixes will be applied to v0.14.x!
gem 'faraday_middleware', '~> 1.0'

# needed by resque-web
gem 'font-awesome-sass', '>= 6.0'

#
# # Use gem version of handle_rest
gem 'handle_rest', git: 'https://github.com/mlibrary/handle_rest', tag: 'v0.0.5'

gem 'hyrax', '4.0'

# Best solution for a yanked gem while we're still on Ruby 2.x, see https://github.com/dryruby/json-canonicalization/issues/2#issuecomment-1841772415
gem 'json-canonicalization', '~>0.4', '>= 0.4'

gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', ref: 'cbffb84ee2db696c8d8a3ca1a0aae7aae37f33fa'

# Use Jekyll for blog and informational pages
gem 'jekyll', '~> 3.9.3'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# jQuery plugin for drop-in fix binded events problem caused by Turbolinks
gem 'jquery-turbolinks'

# Json Web Token
gem 'jwt'

# Keycard provides authentication support and user/request information
gem 'keycard', '~> 0.2.4'

# markdown support for Jekyll, CVE-2020-14001
gem "kramdown", ">= 2.3.0"
gem "kramdown-parser-gfm"

# HELIO-4567, HELIO-4697
gem 'marc', '~> 1.0'

# HELIO-3816
gem 'mimemagic', '~> 0.3.7'

# Use MySQL as the database for Active Record
gem 'mysql2'

# CVE-2019-5477
# CVE-2020-7595
# CVE-2020-26247
gem "nokogiri", ">= 1.13.6"

gem "okcomputer", "~> 1.18.4"

# Force epub search results to be sentences
gem 'pragmatic_segmenter', '~> 0.3'

# Turn page image epub chapters into pdfs
gem 'prawn', '~> 2.2'

gem "rails_semantic_logger", '~> 4.14'

gem 'redcarpet', '~> 3.5.1'

# see HELIO-4484 and https://github.com/samvera/hyrax/pull/5961
gem 'redlock', '>= 0.1.2', '< 2.0'

gem 'resque', '~> 2.6.0'
gem 'resque-pool'
gem 'resque-web', '~> 0.0.12', require: 'resque_web'

gem 'riiif', git: 'https://github.com/mlibrary/riiif', ref: '8c826c34c06c70439b1bb5cadf12800f9fa6e9d9'

gem 'rsolr', '>= 1.1.2', '< 3'

# Use Zip to extract EPubs
gem "rubyzip", ">= 1.3.0"

# to connect to Fulcrum and Firebrand's SFTP servers
gem 'net-sftp', '~> 4.0'

gem 'sitemap_generator', '~> 6.1.2'

gem 'sinatra', '>= 0.9.2'

gem 'sprockets', '~> 3.7'

# sqlite for epub indexing
gem 'sqlite3', '1.4.2'

# SwaggerClient - the Ruby gem for the COUNTER_SUSHI5_0 API
gem 'swagger_client', git: 'https://github.com/mlibrary/swagger_client', branch: 'master'

# https://github.com/samvera/hyrax/pull/5612
# "Version 6 of tinymce-rails causes uglifier to error during assets:precompile"
# This seems to be a hyrax 3.4.1 problem, the next release will have this pin
# in hyrax itself so can be removed
gem 'tinymce-rails', '~> 5.10'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2'

# performance profiling
gem 'skylight', '~> 5.3.4'

# Rails Webpack Tool
gem 'webpacker', '~> 5.4.2'

# puma monitoring, HELIO-3388
gem 'yabeda-rails'
gem 'yabeda-puma-plugin'
gem 'yabeda-prometheus'

group :development, :test do
  gem 'byebug'
  # test coverage with coveralls
  # gem 'coveralls', require: false
  gem 'coveralls_reborn', require: false
  gem 'factory_bot_rails'
  gem "fakefs", require: "fakefs/safe"
  gem "faker"
  gem 'fcrepo_wrapper', git: 'https://github.com/mlibrary/fcrepo_wrapper', branch: 'file-exists-and-downloader-update'
  gem 'json_schemer'
  gem 'rails-controller-testing', '~> 1.0.5'
  gem 'rspec-context-private'
  gem 'rspec-html-matchers'
  # This formatter enables the use of "--format RspecJunitFormatter" when running
  # rspec. Specifically used with circleci so we can get timings for parallelism
  gem 'rspec_junit_formatter'
  gem 'rspec-rails', '~> 5.0'
  gem 'rspec-repeat', '~> 1.0.2'
  gem 'rubocop', '1.22'
  gem 'rubocop-rails', '2.12.2'
  gem 'rubocop-rails_config', '1.7.3'
  gem 'rubocop-rspec', '2.5.0'
  gem 'ruumba', '0.1.2'
  gem 'simple_solr_client', '0.2.0'
  gem 'solr_wrapper', '>= 1.1', '< 3.0'
end

group :development do
  # Capybara save_and_open_page thingy
  gem 'launchy', '~> 2.4.3'
  # Debugger
  gem 'pry-rails'
  # Yay! A Ruby Documentation Tool
  gem 'yard', '>= 0.9.20'
end
