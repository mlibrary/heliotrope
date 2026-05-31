# -*- encoding: utf-8 -*-
# stub: less-rails 4.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "less-rails".freeze
  s.version = "4.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ken Collins".freeze]
  s.date = "2018-10-31"
  s.description = "The dynamic stylesheet language for the Rails asset pipeline. Allows other gems to extend Less load path.".freeze
  s.email = ["ken@metaskills.net".freeze]
  s.homepage = "http://github.com/metaskills/less-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "The dynamic stylesheet language for the Rails asset pipeline.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<less>.freeze, ["~> 2.6.0"])
  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 4"])
  s.add_runtime_dependency(%q<sprockets>.freeze, [">= 2"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<guard>.freeze, [">= 0"])
  s.add_development_dependency(%q<guard-minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails>.freeze, [">= 0"])
end
