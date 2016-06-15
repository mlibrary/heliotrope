source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'

gem 'curation_concerns', '0.14.0'
gem 'active-fedora', '9.10.4'
gem 'resque-web', '~> 0.0.7', require: 'resque_web'
gem 'resque'
gem 'resque-pool'

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
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  gem 'capistrano', '3.4.0'
  gem 'capistrano-rails', '>= 1.1.3'
  gem 'capistrano-bundler'
  gem 'capistrano-rbenv', '~> 2.0'
  gem 'net-ssh-krb', :git => 'https://github.com/Lax/net-ssh-kerberos.git', :branch => 'gssapi', :require => 'net/ssh/kerberos'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

gem 'rsolr', '~> 1.0.6'
gem 'devise'
gem 'devise-guests', '~> 0.3'

group :development, :test do
  gem 'byebug'
  gem 'fcrepo_wrapper', git: "https://github.com/curationexperts/fcrepo_wrapper.git"
  gem 'solr_wrapper', git: "https://github.com/cbeer/solr_wrapper.git"
  gem 'rspec-rails'
  gem 'rubocop', '~> 0.37.2'
  gem 'rubocop-rspec'
  gem 'sqlite3'
  gem 'factory_girl_rails'
  gem 'capybara'
end
