# -*- encoding: utf-8 -*-
# stub: active-fedora 14.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "active-fedora".freeze
  s.version = "14.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Matt Zumwalt".freeze, "McClain Looney".freeze, "Justin Coyne".freeze]
  s.date = "2023-03-07"
  s.description = "ActiveFedora provides for creating and managing objects in the Fedora Repository Architecture.".freeze
  s.email = ["samvera-tech@googlegroups.com".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/samvera/active_fedora".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A convenience libary for manipulating documents in the Fedora Repository.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activemodel>.freeze, [">= 5.1"])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.1"])
  s.add_runtime_dependency(%q<active-triples>.freeze, [">= 0.11.0", "< 2.0.0"])
  s.add_runtime_dependency(%q<deprecation>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1.0"])
  s.add_runtime_dependency(%q<faraday-encoding>.freeze, [">= 0.0.5"])
  s.add_runtime_dependency(%q<ldp>.freeze, [">= 0.7.0", "< 2"])
  s.add_runtime_dependency(%q<rsolr>.freeze, [">= 1.1.2", "< 3"])
  s.add_runtime_dependency(%q<ruby-progressbar>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<bixby>.freeze, [">= 0"])
  s.add_development_dependency(%q<equivalent-xml>.freeze, [">= 0"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, ["~> 0.2"])
  s.add_development_dependency(%q<github_changelog_generator>.freeze, [">= 0"])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5"])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.8"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, ["~> 4.0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
