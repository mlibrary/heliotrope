# -*- encoding: utf-8 -*-
# stub: hydra-core 12.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-core".freeze
  s.version = "12.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Matt Zumwalt, Bess Sadler, Julie Meloni, Naomi Dushay, Jessie Keck, John Scofield, Justin Coyne & many more.  See https://github.com/projecthydra/hydra-head/contributors".freeze]
  s.date = "2023-01-27"
  s.description = "Hydra-Head is a Rails Engine containing the core code for a Hydra application. The full hydra stack includes: Blacklight, Fedora, Solr, active-fedora, solrizer, and om".freeze
  s.email = ["hydra-tech@googlegroups.com".freeze]
  s.homepage = "https://github.com/samvera/hydra-head/tree/master/hydra-core".freeze
  s.licenses = ["APACHE2".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Hydra-Head Rails Engine (requires Rails3)".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<hydra-access-controls>.freeze, ["= 12.1.0"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2", "< 7.1"])
  s.add_development_dependency(%q<rails-controller-testing>.freeze, ["~> 1"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 4.0"])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
end
