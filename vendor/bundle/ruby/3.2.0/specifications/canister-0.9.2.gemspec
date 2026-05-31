# -*- encoding: utf-8 -*-
# stub: canister 0.9.2 ruby lib

Gem::Specification.new do |s|
  s.name = "canister".freeze
  s.version = "0.9.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bryan Hockey".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-08-04"
  s.description = "\n    Canister is a simple IoC container for ruby. It has no dependencies and provides only\n    the functionality you need. It does not monkey-patch ruby or pollute the global\n    namespace, and most importantly it expects to be invisible to your domain classes.\n  ".freeze
  s.email = ["bhock@umich.edu".freeze]
  s.homepage = "https://github.com/mlibrary/canister".freeze
  s.licenses = ["Revised BSD".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A simple IoC container for ruby.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
end
