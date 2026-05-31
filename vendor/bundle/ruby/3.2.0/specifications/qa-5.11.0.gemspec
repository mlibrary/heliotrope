# -*- encoding: utf-8 -*-
# stub: qa 5.11.0 ruby lib

Gem::Specification.new do |s|
  s.name = "qa".freeze
  s.version = "5.11.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stephen Anderson".freeze, "Don Brower".freeze, "Jim Coble".freeze, "Mike Dubin".freeze, "Randall Floyd".freeze, "Eric James".freeze, "Mike Stroming".freeze, "Adam Wead".freeze, "E. Lynette Rayle".freeze]
  s.date = "2023-11-09"
  s.description = "Provides a set of uniform RESTful routes to query any controlled vocabulary or set of authority terms.".freeze
  s.email = ["amsterdamos@gmail.com".freeze]
  s.homepage = "https://github.com/projecthydra/questioning_authority".freeze
  s.licenses = ["APACHE-2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "You should question your authorities.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord-import>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<deprecation>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<faraday>.freeze, ["< 3.0", "!= 2.0.0"])
  s.add_runtime_dependency(%q<geocoder>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<ldpath>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 5.0", "< 7.2"])
  s.add_runtime_dependency(%q<rdf>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, ["~> 5.0", ">= 5.0.2"])
  s.add_development_dependency(%q<rails>.freeze, ["!= 5.2.0", "!= 5.2.1", "!= 5.2.2"])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rdf-n3>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rdf-rdfxml>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<json-ld>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rdf-vocab>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<swagger-docs>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
end
