# -*- encoding: utf-8 -*-
# stub: ld-patch 3.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "ld-patch".freeze
  s.version = "3.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/ld-patch/issues", "documentation_uri" => "https://ruby-rdf.github.io/ld-patch", "homepage_uri" => "https://github.com/ruby-rdf/ld-patch", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/ld-patch" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2023-07-23"
  s.description = "\n    Implements the W3C Linked Data Patch Format and operations for RDF.rb.\n    Makes use of the SPARQL gem for performing updates.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/ld-patch".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "W3C Linked Data Patch Format for RDF.rb.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<ebnf>.freeze, ["~> 2.3"])
  s.add_runtime_dependency(%q<sparql>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<sxp>.freeze, ["~> 1.2"])
  s.add_runtime_dependency(%q<rdf-xsd>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<json-ld>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rack>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rdf-normalize>.freeze, ["~> 0.6"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.18"])
end
