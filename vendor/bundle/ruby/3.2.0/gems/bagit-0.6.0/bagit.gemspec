# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bagit/version"

Gem::Specification.new do |spec|
  spec.name = "bagit"
  spec.version = BagIt::VERSION
  spec.summary = "BagIt package generation and validation"
  spec.description = "Ruby Library and Command Line tools for bagit"
  spec.email = "jamie@jamielittle.org"
  spec.homepage = "http://github.com/tipr/bagit"
  spec.authors = ["Tom Johnson, Francesco Lazzarino, Jamie Little"]
  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.0", "< 3.4"

  spec.add_dependency "validatable", "~> 1.6"
  spec.add_dependency "docopt", "~> 0.5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "standard"

  spec.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
