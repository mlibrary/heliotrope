# -*- encoding: utf-8 -*-
# stub: sparql 3.2.6 ruby lib

Gem::Specification.new do |s|
  s.name = "sparql".freeze
  s.version = "3.2.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/sparql/issues", "documentation_uri" => "https://ruby-rdf.github.io/sparql", "homepage_uri" => "https://github.com/ruby-rdf/sparql", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/sparql" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze, "Arto Bendiken".freeze]
  s.date = "2023-07-23"
  s.description = "SPARQL Implements SPARQL 1.1 Query, Update and result formats for the Ruby RDF.rb library suite.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.executables = ["sparql".freeze]
  s.files = ["bin/sparql".freeze]
  s.homepage = "https://github.com/ruby-rdf/sparql".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "SPARQL Query and Update library for Ruby.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2", ">= 3.2.11"])
  s.add_runtime_dependency(%q<rdf-aggregate-repo>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<ebnf>.freeze, ["~> 2.3", ">= 2.3.5"])
  s.add_runtime_dependency(%q<builder>.freeze, ["~> 3.2", ">= 3.2.4"])
  s.add_runtime_dependency(%q<logger>.freeze, ["~> 1.5"])
  s.add_runtime_dependency(%q<sxp>.freeze, ["~> 1.2", ">= 1.2.4"])
  s.add_runtime_dependency(%q<sparql-client>.freeze, ["~> 3.2", ">= 3.2.2"])
  s.add_runtime_dependency(%q<rdf-xsd>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<sinatra>.freeze, ["~> 3.0", ">= 3.0.5"])
  s.add_development_dependency(%q<rack>.freeze, [">= 2.2", "< 4"])
  s.add_development_dependency(%q<rack-test>.freeze, ["~> 2.1"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<linkeddata>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
