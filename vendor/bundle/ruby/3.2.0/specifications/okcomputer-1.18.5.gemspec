# -*- encoding: utf-8 -*-
# stub: okcomputer 1.18.5 ruby lib

Gem::Specification.new do |s|
  s.name = "okcomputer".freeze
  s.version = "1.18.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Patrick Byrne".freeze, "Andy Fleener".freeze, "Chris Arcand".freeze]
  s.date = "2023-10-28"
  s.description = "\n    Inspired by the simplicity of Fitter Happier, but frustrated by its lack of\n    flexibility, we built OK Computer. Create and register your own custom\n    health checks, or choose from the built-in library of checks to ensure your\n    app is working as intended.\n  ".freeze
  s.email = ["code@patrickbyrne.net".freeze, "anfleene@gmail.com".freeze, "chris@chrisarcand.com".freeze]
  s.homepage = "https://github.com/sportngin/okcomputer".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A simple, extensible health-check monitor".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3.6"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 4.0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<sequel>.freeze, [">= 0"])
end
