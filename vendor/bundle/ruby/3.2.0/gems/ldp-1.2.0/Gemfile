source 'https://rubygems.org'

gem 'activesupport'
gem 'byebug', platforms: [:mri]

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end

# Specify your gem's dependencies in ldp-client.gemspec
gemspec
