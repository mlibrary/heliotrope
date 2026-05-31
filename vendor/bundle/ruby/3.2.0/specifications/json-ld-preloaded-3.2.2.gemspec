# -*- encoding: utf-8 -*-
# stub: json-ld-preloaded 3.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "json-ld-preloaded".freeze
  s.version = "3.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/json-ld-preloaded/issues", "documentation_uri" => "https://ruby-rdf.github.io/json-ld-preloaded", "homepage_uri" => "https://github.com/ruby-rdf/json-ld-preloaded", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/json-ld-preloaded" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2022-10-25"
  s.description = "A meta-release of the json-ld gem including preloaded vocabularies for the Ruby RDF.rb library suite.".freeze
  s.email = "public-linked-json@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/json-ld-preloaded".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "JSON-LD with preloaded contexts for RDF.rb.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<json-ld>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
