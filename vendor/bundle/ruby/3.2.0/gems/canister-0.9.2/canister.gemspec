
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "canister/version"

Gem::Specification.new do |spec|
  spec.name          = "canister"
  spec.version       = Canister::VERSION
  spec.authors       = ["Bryan Hockey"]
  spec.email         = ["bhock@umich.edu"]

  spec.summary       = %q{A simple IoC container for ruby.}
  spec.description   = %q{
    Canister is a simple IoC container for ruby. It has no dependencies and provides only
    the functionality you need. It does not monkey-patch ruby or pollute the global
    namespace, and most importantly it expects to be invisible to your domain classes.
  }
  spec.homepage      = "https://github.com/mlibrary/canister"
  spec.license       = "Revised BSD"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rspec"
end
