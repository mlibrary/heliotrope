# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/context/private/version'

Gem::Specification.new do |spec|
  spec.name          = "rspec-context-private"
  spec.version       = RSpec::Context::Private::VERSION
  spec.authors       = ["Sean Devine"]
  spec.email         = ["barelyknown@icloud.com"]
  spec.summary       = %q{RSpec shared context to make private methods temporarily public.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/barelyknown/rspec-context-private"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

end
