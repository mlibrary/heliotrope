# -*- encoding: utf-8 -*-
# stub: ettin 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ettin".freeze
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bryan Hockey".freeze]
  s.date = "2019-06-27"
  s.description = "Ettin handles loading environment-specific settings in an easy, simple,\n                          and maintainable manner with minimal dependencies or magic.".freeze
  s.email = ["bhock@umich.edu".freeze]
  s.executables = ["ettin".freeze]
  s.files = ["bin/ettin".freeze]
  s.licenses = ["Revised BSD".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "The best way to add settings in any ruby project.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<deep_merge>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
end
