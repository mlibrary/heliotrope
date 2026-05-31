# -*- encoding: utf-8 -*-
# stub: rdf-normalize 0.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rdf-normalize".freeze
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/rdf-normalize/issues", "documentation_uri" => "https://ruby-rdf.github.io/rdf-normalize", "homepage_uri" => "https://github.com/ruby-rdf/rdf-normalize", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/rdf-normalize" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2023-07-17"
  s.description = "RDF::Normalize performs Dataset Canonicalization for RDF.rb.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/rdf-normalize".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "RDF Graph normalizer for Ruby.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
  s.add_development_dependency(%q<json-ld>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rdf-trig>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
