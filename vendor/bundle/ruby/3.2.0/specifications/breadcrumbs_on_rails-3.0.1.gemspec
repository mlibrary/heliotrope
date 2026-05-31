# -*- encoding: utf-8 -*-
# stub: breadcrumbs_on_rails 3.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "breadcrumbs_on_rails".freeze
  s.version = "3.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Simone Carletti".freeze]
  s.date = "2016-08-25"
  s.description = "BreadcrumbsOnRails is a simple Ruby on Rails plugin for creating and managing a breadcrumb navigation for a Rails project.".freeze
  s.email = ["weppos@weppos.net".freeze]
  s.homepage = "https://simonecarletti.com/code/breadcrumbs_on_rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A simple Ruby on Rails plugin for creating and managing a breadcrumb navigation".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails>.freeze, [">= 4.0"])
  s.add_development_dependency(%q<mocha>.freeze, [">= 1.0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
