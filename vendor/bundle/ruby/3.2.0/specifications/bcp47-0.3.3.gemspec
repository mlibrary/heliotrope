# -*- encoding: utf-8 -*-
# stub: bcp47 0.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "bcp47".freeze
  s.version = "0.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Christopher Dell".freeze]
  s.date = "2012-08-30"
  s.description = "A subset of the BCP47 spec implemented in ruby".freeze
  s.email = "chris@tigrish.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/tigrish/bcp47".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A ruby implementation of BCP47".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_runtime_dependency(%q<i18n>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 2.8.0"])
  s.add_development_dependency(%q<rdoc>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.1.0"])
  s.add_development_dependency(%q<jeweler>.freeze, ["~> 1.8.4"])
  s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<localeapp>.freeze, [">= 0"])
end
