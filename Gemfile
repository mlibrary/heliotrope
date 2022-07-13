# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.8.1'

gem 'rails-html-sanitizer', '~> 1.4.3'

# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 5.6.4'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'

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

gem 'rack', '~> 2.2.3'

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
  # https://groups.google.com/forum/#!topic/ruby-capybara/xR77bvMCGUo
  gem 'selenium-webdriver', '~> 3.141.0'
  gem 'webdrivers', '~> 3.0'
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
# Heliotrope
#
##############################################################################

gem 'blacklight_oai_provider', "~> 6.1.1"

# HELIO-2531
gem "sassc", ">= 2.0.0"
gem "bootstrap-sass", ">= 3.4.1"

# A rails 5.2 thing. Might make startup faster. Not sure if it really matters though.
# I guess we'll see.
# https://github.com/Shopify/bootsnap
gem 'bootsnap', '~> 1.4.6'

# Canister provides containers
gem 'canister', '~> 0.9.0'

gem 'carrierwave', '~> 1.3.2'

# Checkpoint provides authorization support
gem 'checkpoint', '~> 1.1.0'

# clamav only in production
gem 'clamby', '~> 1.5.1', group: :production

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
gem 'faraday', '~> 0.9'
# NOTE: This is the last minor release in the v0.x series, next release will be 1.0 to match Faraday v1.0 release and from then on only fixes will be applied to v0.14.x!
gem 'faraday_middleware', '~> 0.14.0'

# needed by resque-web
gem 'font-awesome-sass', '>= 6.0'

#
# # Use gem version of handle_rest
gem 'handle_rest', git: 'https://github.com/mlibrary/handle_rest', ref: 'baed402b5a530eb57e838443ce292ec3f46cd5e6'

gem 'hyrax', '3.4.1'

# pinned for Jekyll
gem 'i18n', '~> 0.7'

gem 'irus_analytics', git: 'https://github.com/mlibrary/irus_analytics', ref: '0de9a17b2f764a0ce7bdd1d0221c60b88c2643e7'

# Use Jekyll for blog and informational pages
gem 'jekyll', '~> 3.9.0'

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

# HELIO-3816
gem 'mimemagic', '~> 0.3.7'

# Use MySQL as the database for Active Record
gem 'mysql2', '~> 0.4.10'

# CVE-2019-5477
# CVE-2020-7595
# CVE-2020-26247
gem "nokogiri", ">= 1.13.6"

gem "okcomputer", "~> 1.18.4"

# Read PDF ToC
gem 'origami'

# Force epub search results to be sentences
gem 'pragmatic_segmenter', '~> 0.3'

# Turn page image epub chapters into pdfs
gem 'prawn', '~> 2.2'

gem 'redcarpet', '~> 3.5.1'
gem 'reverse_markdown'

gem 'resque', '~> 2.2.1 '
gem 'resque-pool'
gem 'resque-web', '~> 0.0.12', require: 'resque_web'

gem 'riiif', '1.4.1'

gem 'rsolr', '~> 2.0.1'

# Use Zip to extract EPubs
gem "rubyzip", ">= 1.3.0"

gem 'sitemap_generator', '~> 6.1.2'

gem 'sinatra', '~> 2.2.0'
# CVE-2018-3760
gem 'sprockets', '~> 3.7.2'

# sqlite for epub indexing
gem 'sqlite3'

# SwaggerClient - the Ruby gem for the COUNTER_SUSHI5_0 API
gem 'swagger_client', git: 'https://github.com/mlibrary/swagger_client', branch: 'master'

# https://github.com/samvera/hyrax/pull/5612
# "Version 6 of tinymce-rails causes uglifier to error during assets:precompile"
# This seems to be a hyrax 3.4.1 problem, the next release will have this pin
# in hyrax itself so can be removed
gem 'tinymce-rails', '~> 5.10'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2'

# Talking to Google Analytics
gem 'legato', '~> 0.3'
gem 'oauth'
gem 'oauth2', '~> 1.2'
gem 'signet'

# performance profiling
gem 'skylight', '~> 5.0.0.beta4'

# Rails Webpack Tool
gem 'webpacker', '~> 5.4.2'

# puma monitoring, HELIO-3388
gem 'yabeda-rails'
gem 'yabeda-puma-plugin'
gem 'yabeda-prometheus'

group :development, :test do
  gem 'byebug'
  # test coverage with coveralls
  gem 'coveralls', require: false
  gem 'factory_bot_rails'
  gem "fakefs", require: "fakefs/safe"
  gem "faker"
  gem 'fcrepo_wrapper', '0.5.2'
  gem 'json_schemer'
  gem 'rails-controller-testing'
  gem 'rspec-context-private'
  gem 'rspec-html-matchers'
  # This formatter enables the use of "--format RspecJunitFormatter" when running
  # rspec. Specifically used with circleci so we can get timings for parallelism
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rspec-repeat', '~> 1.0.2'
  gem 'rubocop', '~> 1.22'
  gem 'rubocop-rails', '~> 2.11', '>= 2.11.3'
  gem 'rubocop-rails_config', '~> 1.7', '>= 1.7.1'
  gem 'rubocop-rspec', '~> 2.5'
  gem 'ruumba', '0.1.2'
  gem 'simple_solr_client'
  gem 'solr_wrapper', '>= 1.1', '< 3.0'
end

group :development do
  # Capybara save_and_open_page thingy
  gem 'launchy', '~> 2.4.3'
  # Debugger
  gem 'pry-rails', '~> 0.3.4'
  # Yay! A Ruby Documentation Tool
  gem 'yard', '>= 0.9.20'
end
