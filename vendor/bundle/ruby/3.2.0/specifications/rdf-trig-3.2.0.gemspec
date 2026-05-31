# -*- encoding: utf-8 -*-
# stub: rdf-trig 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rdf-trig".freeze
  s.version = "3.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2021-12-13"
  s.description = "RDF::TriG is an TriG reader/writer for the RDF.rb library suite.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/rdf-trig".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "TriG reader/writer for Ruby.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<ebnf>.freeze, ["~> 2.2"])
  s.add_runtime_dependency(%q<rdf-turtle>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<json-ld>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rdf-isomorphic>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
end
