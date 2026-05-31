# -*- encoding: utf-8 -*-
# stub: ldpath 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ldpath".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Beer".freeze]
  s.date = "2020-01-21"
  s.email = ["cabeer@stanford.edu".freeze]
  s.executables = ["ldpath".freeze]
  s.files = ["bin/ldpath".freeze]
  s.homepage = "https://github.com/samvera-labs/ldpath".freeze
  s.licenses = ["Apache 2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Ruby implementation of LDPath".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<parslet>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.8"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rdf-reasoner>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
end
