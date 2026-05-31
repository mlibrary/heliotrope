# -*- encoding: utf-8 -*-
# stub: sparql-client 3.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "sparql-client".freeze
  s.version = "3.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/sparql-client/issues", "documentation_uri" => "https://ruby-rdf.github.io/sparql-client", "homepage_uri" => "https://github.com/ruby-rdf/sparql-client", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/sparql-client" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arto Bendiken".freeze, "Ben Lavender".freeze, "Gregg Kellogg".freeze]
  s.date = "2023-07-23"
  s.description = "Executes SPARQL queries and updates against a remote SPARQL 1.0 or 1.1 endpoint,\n                            or against a local repository. Generates SPARQL queries using a simple DSL.\n                            Includes SPARQL::Client::Repository, which allows any endpoint supporting\n                            SPARQL Update to be used as an RDF.rb repository.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/sparql-client".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "SPARQL client for RDF.rb.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2", ">= 3.2.11"])
  s.add_runtime_dependency(%q<net-http-persistent>.freeze, ["~> 4.0", ">= 4.0.2"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<sparql>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.14"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
