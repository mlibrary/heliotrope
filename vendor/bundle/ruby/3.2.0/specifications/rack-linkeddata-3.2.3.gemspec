# -*- encoding: utf-8 -*-
# stub: rack-linkeddata 3.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-linkeddata".freeze
  s.version = "3.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/rack-linkeddata/issues", "documentation_uri" => "https://ruby-rdf.github.io/rack-linkeddata", "homepage_uri" => "https://github.com/ruby-rdf/rack-linkeddata", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/rack-linkeddata" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arto Bendiken".freeze, "Gregg Kellogg".freeze]
  s.date = "2023-07-23"
  s.description = "Rack middleware for Linked Data content negotiation.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/rack-linkeddata".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Linked Data content negotiation for Rack applications.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<linkeddata>.freeze, ["~> 3.2", ">= 3.2.2"])
  s.add_runtime_dependency(%q<rack-rdf>.freeze, ["~> 3.2", ">= 3.2.3"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.2", "< 4"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rack-test>.freeze, ["~> 2.1"])
end
