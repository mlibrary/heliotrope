# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scrub_rb/version'

Gem::Specification.new do |spec|
  spec.name          = "scrub_rb"
  spec.version       = ScrubRb::VERSION
  spec.authors       = ["Jonathan Rochkind"]
  spec.email         = ["jonathan@dnil.net"]
  spec.summary       = %q{Pure-ruby polyfill of MRI 2.1 String#scrub, for ruby 1.9 and 2.0 any interpreter
}
  spec.homepage      = "https://github.com/jrochkind/scrub_rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
