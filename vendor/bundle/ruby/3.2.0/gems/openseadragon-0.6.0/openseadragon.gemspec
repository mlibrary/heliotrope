# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openseadragon/version'

Gem::Specification.new do |spec|
  spec.name          = "openseadragon"
  spec.version       = Openseadragon::VERSION
  spec.authors       = ["Justin Coyne", "Chris Beer", "Christopher Jesudurai"]
  spec.email         = ["justin@curationexperts.com", "cabeer@stanford.edu", "jchris@stanford.edu"],
  spec.summary       = %q{OpenSeadragon assets and helpers for Rails. http://openseadragon.github.io/}
  spec.description   = %q{OpenSeadragon is a javascript library for displaying tiling images. This gem packages those assets and some Rails helpers for using them}
  spec.homepage      = "https://github.com/iiif/openseadragon-rails"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "engine_cart"
  spec.add_development_dependency "rspec-rails", '~> 3.1'
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "sqlite3"

  spec.add_dependency 'rails', '> 3.2.0'
end
