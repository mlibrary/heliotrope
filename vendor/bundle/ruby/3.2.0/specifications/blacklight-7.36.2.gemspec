# -*- encoding: utf-8 -*-
# stub: blacklight 7.36.2 ruby lib

Gem::Specification.new do |s|
  s.name = "blacklight".freeze
  s.version = "7.36.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jonathan Rochkind".freeze, "Matt Mitchell".freeze, "Chris Beer".freeze, "Jessie Keck".freeze, "Jason Ronallo".freeze, "Vernon Chapman".freeze, "Mark A. Matienzo".freeze, "Dan Funk".freeze, "Naomi Dushay".freeze, "Justin Coyne".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-01-22"
  s.description = "Blacklight is an open source Solr user interface discovery platform.\n    You can use Blacklight to enable searching and browsing of your\n    collections. Blacklight uses the Apache Solr search engine to search\n    full text and/or metadata.".freeze
  s.email = ["blacklight-development@googlegroups.com".freeze]
  s.homepage = "http://projectblacklight.org/".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Blacklight provides a discovery interface for any Solr (http://lucene.apache.org/solr) index.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 5.1", "< 7.2"])
  s.add_runtime_dependency(%q<globalid>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<jbuilder>.freeze, ["~> 2.7"])
  s.add_runtime_dependency(%q<kaminari>.freeze, [">= 0.15"])
  s.add_runtime_dependency(%q<deprecation>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<i18n>.freeze, [">= 1.7.0"])
  s.add_runtime_dependency(%q<ostruct>.freeze, [">= 0.3.2"])
  s.add_runtime_dependency(%q<view_component>.freeze, [">= 2.66", "< 4"])
  s.add_runtime_dependency(%q<hashdiff>.freeze, [">= 0"])
  s.add_development_dependency(%q<rsolr>.freeze, [">= 1.0.6", "< 3"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 5.0"])
  s.add_development_dependency(%q<rspec-collection_matchers>.freeze, [">= 1.0"])
  s.add_development_dependency(%q<axe-core-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<capybara>.freeze, ["~> 3"])
  s.add_development_dependency(%q<selenium-webdriver>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.1"])
  s.add_development_dependency(%q<equivalent-xml>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.85"])
  s.add_development_dependency(%q<rubocop-rails>.freeze, ["~> 2.6"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 1.43"])
  s.add_development_dependency(%q<i18n-tasks>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
end
