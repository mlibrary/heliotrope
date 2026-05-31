# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hydra/works/version'
DO_NOT_SHIP          = ['spec/fixtures/eicar.txt']

Gem::Specification.new do |spec|
  spec.name          = 'hydra-works'
  spec.version       = Hydra::Works::VERSION
  spec.authors       = ['Justin Coyne']
  spec.email         = ['justin@curationexperts.com']
  spec.summary       = %q{Fundamental repository data model for Samvera applications}
  spec.description   = %q{Using this data model should enable easy collaboration amongst Samvera projects.}
  spec.homepage      = 'https://github.com/samvera/hydra-works'
  spec.license       = 'APACHE2'
  spec.metadata      = { "rubygems_mfa_required" => "true" }

  spec.files         = `git ls-files -z`.split("\x0") - DO_NOT_SHIP
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 5.2', '< 7.1'
  spec.add_dependency 'hydra-derivatives', '~> 3.6'
  spec.add_dependency 'hydra-file_characterization', '~> 1.0'
  spec.add_dependency 'hydra-pcdm', '>= 0.9'

  spec.add_development_dependency 'bundler', '>= 1.7'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'fcrepo_wrapper'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'solr_wrapper'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rspec_junit_formatter'
end
