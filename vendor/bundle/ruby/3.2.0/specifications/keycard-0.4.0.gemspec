# -*- encoding: utf-8 -*-
# stub: keycard 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "keycard".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Noah Botimer".freeze, "Aaron Elkiss".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.email = ["botimer@umich.edu".freeze, "aelkiss@umich.edu".freeze]
  s.homepage = "https://github.com/mlibrary/keycard".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Keycard provides authentication support and user/request information, especially in Rails applications.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<sequel>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<logger>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov-lcov>.freeze, [">= 0"])
  s.add_development_dependency(%q<ostruct>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.53"])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 2.9.0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
