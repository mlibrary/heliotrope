# -*- encoding: utf-8 -*-
# stub: simple_solr_client 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "simple_solr_client".freeze
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bill Dueber".freeze]
  s.date = "2018-07-27"
  s.email = ["bill@dueber.com".freeze]
  s.executables = ["solr_shell".freeze]
  s.files = ["bin/solr_shell".freeze]
  s.homepage = "https://github.com/billdueber/simple_solr".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Interact with a Solr API via JSON".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<httpclient>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest-reporters>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<pry>.freeze, [">= 0"])
end
