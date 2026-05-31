# -*- encoding: utf-8 -*-
# stub: rdf-hamster-repo 3.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rdf-hamster-repo".freeze
  s.version = "3.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2021-12-30"
  s.description = "An in-memory implementation of RDF::Repository using an efficient, immutable, and thread-safe Hash.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/rdf-hamster-repo".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "An RDF repository implementation using an in-memory Hamster Hash.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<hamster>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
