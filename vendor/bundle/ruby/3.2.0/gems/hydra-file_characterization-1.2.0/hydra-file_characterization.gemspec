# -*- encoding: utf-8 -*-
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hydra/file_characterization/version'

Gem::Specification.new do |gem|
  gem.name          = "hydra-file_characterization"
  gem.version       = Hydra::FileCharacterization::VERSION
  gem.authors       = [
    "James Treacy",
    "Jeremy Friesen",
    "Sue Richeson",
    "Rajesh Balekai"
  ]
  gem.email = [
    "jatr@kb.dk",
    "jeremy.n.friesen@gmail.com",
    "spr7b@virginia.edu",
    "rbalekai@gmail.com"
  ]
  gem.description   = 'To provide a wrapper for file characterization'
  gem.summary       = 'To provide a wrapper for file characterization'
  gem.homepage      = "https://github.com/projecthydra/hydra-file_characterization"
  gem.license = "APACHE2"

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.metadata      = { "rubygems_mfa_required" => "true" }

  gem.add_dependency "activesupport", ">= 3.0.0"
  gem.add_development_dependency 'bixby'
  gem.add_development_dependency 'coveralls'
  gem.add_development_dependency 'github_changelog_generator'
  gem.add_development_dependency "guard"
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency 'rspec_junit_formatter'
end
