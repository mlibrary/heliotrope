# -*- encoding: utf-8 -*-
# stub: hydra-head 12.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-head".freeze
  s.version = "12.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Matt Zumwalt, Bess Sadler, Julie Meloni, Naomi Dushay, Jessie Keck, John Scofield, Justin Coyne & many more.  See https://github.com/projecthydra/hydra-head/contributors".freeze]
  s.date = "2023-01-27"
  s.description = "Hydra-Head is a Rails Engine containing the core code for a Hydra application.".freeze
  s.email = ["hydra-tech@googlegroups.com".freeze]
  s.homepage = "https://github.com/samvera/hydra-head".freeze
  s.licenses = ["APACHE-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Hydra-Head Rails Engine".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<hydra-access-controls>.freeze, ["= 12.1.0"])
  s.add_runtime_dependency(%q<hydra-core>.freeze, ["= 12.1.0"])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 5.2", "< 7.1"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.3"])
  s.add_development_dependency(%q<factory_bot>.freeze, [">= 0"])
  s.add_development_dependency(%q<factory_bot_rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, ["~> 3.1"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails-controller-testing>.freeze, [">= 0"])
end
