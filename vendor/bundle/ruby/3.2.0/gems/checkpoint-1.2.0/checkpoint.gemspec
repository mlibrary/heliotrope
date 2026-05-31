# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "checkpoint/version"

Gem::Specification.new do |spec|
  spec.name = "checkpoint"
  spec.version = Checkpoint::VERSION
  spec.authors = ["Noah Botimer", "Aaron Elkiss"]
  spec.email = ["botimer@umich.edu", "aelkiss@umich.edu"]
  spec.license = "BSD-3-Clause"

  spec.summary = <<~SUMMARY
    Checkpoint provides a model and infrastructure for policy-based authorization,
    especially in Rails applications.
  SUMMARY

  spec.homepage = "https://github.com/mlibrary/checkpoint"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "ettin", "~> 1.1"
  spec.add_dependency "sequel", "~> 5.100"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "logger"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-lcov"
  spec.add_development_dependency "ostruct"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.53"
  spec.add_development_dependency "sqlite3", "~> 2.9"
  spec.add_development_dependency "yard", "~> 0.9"
end
