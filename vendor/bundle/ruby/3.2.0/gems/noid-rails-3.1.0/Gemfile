# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in noid-rails.gemspec
gemspec

group :development, :test do
  gem 'coveralls', require: false
  gem 'pry-byebug' unless ENV['CI']
end

# BEGIN ENGINE_CART BLOCK
# engine_cart: 1.0.1
# engine_cart stanza: 0.10.0
# the below comes from engine_cart, a gem used to test this Rails engine gem in the context of a Rails app.
internal_test_gemfile_path = File.expand_path('.internal_test_app', File.dirname(__FILE__))
gemfile_path = ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || internal_test_gemfile_path
file = File.expand_path('Gemfile', gemfile_path)

if File.exist?(file)
  begin
    eval_gemfile(file)
  rescue Bundler::GemfileError => e
    Bundler.ui.warn '[EngineCart] Skipping Rails application dependencies:'
    Bundler.ui.warn e.message
  end
else
  Bundler.ui.warn "[EngineCart] Unable to find test application dependencies in #{file}, using placeholder dependencies"

  if ENV['RAILS_VERSION']
    if ENV['RAILS_VERSION'] == 'edge'
      gem 'rails', github: 'rails/rails'
      ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
    else
      gem 'rails', ENV['RAILS_VERSION']
    end

    case ENV['RAILS_VERSION']
    when /^5\.2/
      gem 'sass-rails', '~> 5.1'
    when /^5\.1/
      gem 'sass-rails', '5.0.7'
    else
      gem 'sass-rails'
    end
  end
end
# END ENGINE_CART BLOCK
