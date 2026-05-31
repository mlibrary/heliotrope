# -*- encoding: utf-8 -*-
# stub: hydra-editor 6.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-editor".freeze
  s.version = "6.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze, "David Chandek-Stark".freeze, "Thomas Johnson".freeze]
  s.date = "2023-02-06"
  s.description = "A basic metadata editor for hydra-head".freeze
  s.email = ["samvera-tech@googlegroups.com".freeze]
  s.homepage = "http://github.com/samvera/hydra-editor".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A basic metadata editor for hydra-head".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.2", "< 7.1"])
  s.add_runtime_dependency(%q<active-fedora>.freeze, [">= 9.0.0"])
  s.add_runtime_dependency(%q<almond-rails>.freeze, ["~> 0.1"])
  s.add_runtime_dependency(%q<cancancan>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<psych>.freeze, ["~> 3.3", "< 4"])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 5.2", "< 7.1"])
  s.add_runtime_dependency(%q<simple_form>.freeze, [">= 4.1.0", "< 5.2"])
  s.add_runtime_dependency(%q<sprockets>.freeze, [">= 3.7"])
  s.add_runtime_dependency(%q<sprockets-es6>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, [">= 0"])
  s.add_development_dependency(%q<capybara>.freeze, ["~> 2.4"])
  s.add_development_dependency(%q<devise>.freeze, ["~> 4.0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.2"])
  s.add_development_dependency(%q<factory_bot_rails>.freeze, ["~> 4.8"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<hydra-head>.freeze, [">= 10.5"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails-controller-testing>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 4"])
  s.add_development_dependency(%q<sdoc>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.16"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
end
