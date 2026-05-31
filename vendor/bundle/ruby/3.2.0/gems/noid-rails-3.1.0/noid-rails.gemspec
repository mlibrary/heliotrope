# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'noid/rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'noid-rails'
  spec.version       = Noid::Rails::VERSION
  spec.authors       = ['Michael J. Giarlo']
  spec.email         = ['leftwing@alumni.rutgers.edu']
  spec.summary       = 'Noid identifier services for Rails-based applications'
  spec.description   = 'Noid identifier services for Rails-based applications.'
  spec.homepage      = 'https://github.com/samvera/noid-rails'
  spec.license       = 'Apache2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_dependency 'actionpack', '>= 5.0.0', '< 7.1'
  spec.add_dependency 'noid', '~> 0.9'

  spec.add_development_dependency 'bixby', '~> 5.0.0'
  spec.add_development_dependency 'bundler', '>= 2.1'
  spec.add_development_dependency 'engine_cart', '~> 2.2'
  spec.add_development_dependency 'rake', '>= 11'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'sqlite3'
end
