# -*- encoding: utf-8 -*-
# stub: linkeddata 3.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "linkeddata".freeze
  s.version = "3.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/rdf/issues", "documentation_uri" => "http://rdf.greggkellogg.net/yard/index.html", "homepage_uri" => "https://github.com/ruby-rdf/linkeddata", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/linkeddata" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arto Bendiken".freeze, "Ben Lavender".freeze, "Gregg Kellogg".freeze, "Tom Johnson".freeze]
  s.date = "2023-07-23"
  s.description = "A metadistribution of RDF.rb including a full set of parsing/serialization plugins.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://ruby-rdf.github.io/linkeddata".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Linked Data for Ruby.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-aggregate-repo>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-hamster-repo>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-isomorphic>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-json>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<rdf-microdata>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-n3>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-normalize>.freeze, ["~> 0.6", ">= 0.6.1"])
  s.add_runtime_dependency(%q<rdf-ordered-repo>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-rdfa>.freeze, ["~> 3.2", ">= 3.2.3"])
  s.add_runtime_dependency(%q<rdf-rdfxml>.freeze, ["~> 3.2", ">= 3.2.2"])
  s.add_runtime_dependency(%q<rdf-reasoner>.freeze, ["~> 0.8"])
  s.add_runtime_dependency(%q<rdf-tabular>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-trig>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<rdf-trix>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<rdf-turtle>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<rdf-vocab>.freeze, ["~> 3.2", ">= 3.2.7"])
  s.add_runtime_dependency(%q<rdf-xsd>.freeze, ["~> 3.2", ">= 3.2.1"])
  s.add_runtime_dependency(%q<json-ld>.freeze, ["~> 3.2", ">= 3.2.5"])
  s.add_runtime_dependency(%q<json-ld-preloaded>.freeze, ["~> 3.2", ">= 3.2.2"])
  s.add_runtime_dependency(%q<ld-patch>.freeze, ["~> 3.2", ">= 3.2.2"])
  s.add_runtime_dependency(%q<shacl>.freeze, ["~> 0.3"])
  s.add_runtime_dependency(%q<shex>.freeze, ["~> 0.7", ">= 0.7.1"])
  s.add_runtime_dependency(%q<sparql>.freeze, ["~> 3.2", ">= 3.2.6"])
  s.add_runtime_dependency(%q<sparql-client>.freeze, ["~> 3.2", ">= 3.2.2"])
  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.13", ">= 1.13.8"])
  s.add_runtime_dependency(%q<yaml-ld>.freeze, ["~> 0.0"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
end
