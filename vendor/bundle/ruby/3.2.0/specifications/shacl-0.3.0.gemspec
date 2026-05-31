# -*- encoding: utf-8 -*-
# stub: shacl 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "shacl".freeze
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/shacl/issues", "documentation_uri" => "https://ruby-rdf.github.io/shacl", "homepage_uri" => "https://github.com/ruby-rdf/shacl", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/shacl" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2022-06-07"
  s.description = "SHACL is an Shape Constraint engine for the Ruby RDF.rb library suite.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/shacl".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Implementation of Shapes Constraint Language (SHACL) for RDF.rb".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2", ">= 3.2.8"])
  s.add_runtime_dependency(%q<json-ld>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<sxp>.freeze, ["~> 1.2"])
  s.add_runtime_dependency(%q<sparql>.freeze, ["~> 3.2", ">= 3.2.4"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rdf-turtle>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rdf-vocab>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rdf-xsd>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
