# -*- encoding: utf-8 -*-
# stub: ssrf_filter 1.0.8 ruby lib

Gem::Specification.new do |s|
  s.name = "ssrf_filter".freeze
  s.version = "1.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arkadiy Tetelman".freeze]
  s.date = "2022-08-04"
  s.description = "A gem that makes it easy to prevent server side request forgery (SSRF) attacks".freeze
  s.homepage = "https://github.com/arkadiyt/ssrf_filter".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A gem that makes it easy to prevent server side request forgery (SSRF) attacks".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler-audit>.freeze, ["~> 0.6.1"])
  s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8.22"])
  s.add_development_dependency(%q<psych>.freeze, ["< 4"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8.0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 3.5.1"])
  s.add_development_dependency(%q<webrick>.freeze, [">= 0"])
  s.add_development_dependency(%q<public_suffix>.freeze, ["= 2.0.5"])
  s.add_development_dependency(%q<rexml>.freeze, ["= 3.2.4"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.50.0"])
end
