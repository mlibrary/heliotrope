# -*- encoding: utf-8 -*-
# stub: solr_wrapper 2.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "solr_wrapper".freeze
  s.version = "2.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Beer".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-02-18"
  s.email = ["chris@cbeer.info".freeze]
  s.executables = ["solr_wrapper".freeze]
  s.files = ["exe/solr_wrapper".freeze]
  s.homepage = "https://github.com/cbeer/solr_wrapper".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Solr 5 service wrapper".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<ruby-progressbar>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<retriable>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.7", "< 3"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0", "< 13"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<simple_solr_client>.freeze, ["= 0.2.0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
end
