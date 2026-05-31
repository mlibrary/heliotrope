# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'valkyrie/version'

Gem::Specification.new do |spec|
  spec.name          = "valkyrie"
  spec.version       = Valkyrie::VERSION
  spec.authors       = ["Trey Pendragon"]
  spec.email         = ["tpendragon@princeton.edu"]

  spec.summary       = 'An ORM using the Data Mapper pattern, specifically built to solve Digital Repository use cases.'
  spec.homepage      = "https://github.com/samvera/valkyrie"
  spec.metadata      = { "rubygems_mfa_required" => "true" }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'dry-struct'
  spec.add_dependency 'activemodel'
  spec.add_dependency 'dry-types', '~> 1.0'
  spec.add_dependency 'rdf', '~> 3.0', '>= 3.0.10'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'railties' # To use generators and engines
  spec.add_dependency 'reform', '~> 2.2'
  spec.add_dependency 'reform-rails'
  spec.add_dependency 'json-ld'
  spec.add_dependency 'json'
  spec.add_dependency 'rdf-vocab'
  spec.add_dependency 'faraday', '>= 0.9', '!= 2.0.0', '< 3'
  spec.add_dependency 'faraday-multipart'

  spec.add_development_dependency "bundler", "> 1.16.0", "< 3"
  spec.add_development_dependency "rake", ">= 10"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "bixby"
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'solr_wrapper'
  spec.add_development_dependency 'fcrepo_wrapper'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'appraisal'
end
