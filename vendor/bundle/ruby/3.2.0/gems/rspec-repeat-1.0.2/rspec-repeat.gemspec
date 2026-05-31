# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/repeat/version'

Gem::Specification.new do |spec|
  spec.name          = 'rspec-repeat'
  spec.version       = RSpec::Repeat::VERSION
  spec.authors       = ['Rico Sta. Cruz']
  spec.email         = ['rico@ricostacruz.com']

  spec.summary       = %q(Retry an RSpec test until it succeeds)
  spec.description   = %q(Retry an RSpec test until it succeeds)
  spec.homepage      = 'https://github.com/rstacruz/rspec-repeat'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split("\n").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_dependency 'rspec', '~> 3.0'
end
