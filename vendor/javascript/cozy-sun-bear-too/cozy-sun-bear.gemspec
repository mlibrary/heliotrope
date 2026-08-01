# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cozy/sun/bear/version'

Gem::Specification.new do |spec|
  spec.name          = "cozy-sun-bear"
  spec.version       = Cozy::Sun::Bear::VERSION
  spec.authors       = ["Roger Espinosa"]
  spec.email         = ["roger@umich.edu"]

  spec.summary       = %q{Include cozy-sun-bear library in Rails app.}
  spec.description   = %q{Much ink can be spilled spinning tales of how we got here.}
  spec.homepage      = "https://github.com/mlibrary/cozy-sun-bear"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # spec.files         = `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end
  spec.files = Dir["{lib,dist,vendor}/**/*"] + ["README.md"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "railties", ">= 3.1.1"

end
