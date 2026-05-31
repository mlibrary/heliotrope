# -*- encoding: utf-8 -*-
# stub: blacklight-gallery 4.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "blacklight-gallery".freeze
  s.version = "4.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Beer".freeze]
  s.date = "2022-10-25"
  s.email = ["cabeer@stanford.edu".freeze]
  s.homepage = "https://github.com/projectblacklight/blacklight-gallery".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Gallery display for Blacklight".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 5.1", "< 8"])
  s.add_runtime_dependency(%q<blacklight>.freeze, ["~> 7.17"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.1"])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-activemodel-mocks>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-collection_matchers>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
  s.add_development_dependency(%q<webdrivers>.freeze, [">= 0"])
  s.add_development_dependency(%q<rexml>.freeze, [">= 0"])
  s.add_development_dependency(%q<selenium-webdriver>.freeze, [">= 3.13.1"])
end
