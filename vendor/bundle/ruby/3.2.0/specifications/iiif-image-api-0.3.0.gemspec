# -*- encoding: utf-8 -*-
# stub: iiif-image-api 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "iiif-image-api".freeze
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-10-16"
  s.description = "Ruby APIs for working with IIIF".freeze
  s.email = ["jcoyne@justincoyne.com".freeze]
  s.homepage = "https://github.com/samvera-labs/iiif-image-api".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Ruby APIs for working with IIIF".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
