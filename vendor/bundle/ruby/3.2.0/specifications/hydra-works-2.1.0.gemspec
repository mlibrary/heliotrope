# -*- encoding: utf-8 -*-
# stub: hydra-works 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-works".freeze
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze]
  s.date = "2023-02-14"
  s.description = "Using this data model should enable easy collaboration amongst Samvera projects.".freeze
  s.email = ["justin@curationexperts.com".freeze]
  s.homepage = "https://github.com/samvera/hydra-works".freeze
  s.licenses = ["APACHE2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Fundamental repository data model for Samvera applications".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2", "< 7.1"])
  s.add_runtime_dependency(%q<hydra-derivatives>.freeze, ["~> 3.6"])
  s.add_runtime_dependency(%q<hydra-file_characterization>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<hydra-pcdm>.freeze, [">= 0.9"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.7"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
end
