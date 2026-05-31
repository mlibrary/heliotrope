source 'https://rubygems.org'

group :development, :test do
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'rspec_junit_formatter'
end

# Specify your gem's dependencies in hydra-pcdm.gemspec
gemspec

# rubocop:disable Bundler/DuplicatedGem
if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end
# rubocop:enable Bundler/DuplicatedGem
