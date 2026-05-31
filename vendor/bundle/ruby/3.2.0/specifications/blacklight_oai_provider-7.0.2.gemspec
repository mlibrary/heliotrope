# -*- encoding: utf-8 -*-
# stub: blacklight_oai_provider 7.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "blacklight_oai_provider".freeze
  s.version = "7.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Beer".freeze, "Carla Galarza".freeze]
  s.date = "2022-04-29"
  s.email = ["chris@cbeer.info".freeze, "cmg2228@columbia.edu".freeze]
  s.homepage = "http://projectblacklight.org/".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Blacklight Oai Provider plugin".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<blacklight>.freeze, ["~> 7.0"])
  s.add_runtime_dependency(%q<oai>.freeze, ["~> 1.2"])
  s.add_runtime_dependency(%q<rexml>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, [">= 0"])
  s.add_development_dependency(%q<webdrivers>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<selenium-webdriver>.freeze, [">= 3.13.1"])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.64.0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 1.8"])
end
