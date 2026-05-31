# -*- encoding: utf-8 -*-
# stub: hydra-pcdm 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-pcdm".freeze
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["E. Lynette Rayle".freeze]
  s.date = "2023-04-21"
  s.description = "Portland Common Data Model (PCDM)".freeze
  s.email = ["elr37@cornell.edu".freeze]
  s.homepage = "https://github.com/samvera/hydra-pcdm".freeze
  s.licenses = ["APACHE2".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Portland Common Data Model (PCDM)".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<active-fedora>.freeze, [">= 10", "< 15"])
  s.add_runtime_dependency(%q<mime-types>.freeze, [">= 1"])
  s.add_runtime_dependency(%q<rdf-vocab>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, [">= 5.0.2"])
  s.add_development_dependency(%q<coveralls_reborn>.freeze, ["~> 0.24"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
end
