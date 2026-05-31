# -*- encoding: utf-8 -*-
# stub: almond-rails 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "almond-rails".freeze
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze]
  s.date = "2020-01-23"
  s.description = "See: https://github.com/requirejs/almond".freeze
  s.email = ["jcoyne@justincoyne.com".freeze]
  s.homepage = "https://github.com/jcoyne/almond_rails".freeze
  s.licenses = ["APACHE2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Almond.js packaged as a Rails engine".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 4.2"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
end
