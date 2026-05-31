# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blacklight/gallery/version'

Gem::Specification.new do |spec|
  spec.name          = "blacklight-gallery"
  spec.version       = Blacklight::Gallery::VERSION
  spec.authors       = ["Chris Beer"]
  spec.email         = ["cabeer@stanford.edu"]
  spec.summary       = %q{Gallery display for Blacklight}
  spec.homepage      = "https://github.com/projectblacklight/blacklight-gallery"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", '>= 5.1', '< 8'
  spec.add_dependency 'blacklight', '~> 7.17'

  spec.add_development_dependency "rake"
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency "rspec-rails", "~> 3.1"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rspec-activemodel-mocks"
  spec.add_development_dependency "rspec-collection_matchers"
  spec.add_development_dependency "solr_wrapper"
  spec.add_development_dependency "engine_cart", "~> 2.0"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency 'webdrivers'
  spec.add_development_dependency 'rexml' # pending https://github.com/SeleniumHQ/selenium/issues/9001
  spec.add_development_dependency "selenium-webdriver", '>= 3.13.1'
end
