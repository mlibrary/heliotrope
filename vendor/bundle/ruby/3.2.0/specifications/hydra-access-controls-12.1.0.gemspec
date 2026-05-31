# -*- encoding: utf-8 -*-
# stub: hydra-access-controls 12.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-access-controls".freeze
  s.version = "12.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Beer".freeze, "Justin Coyne".freeze, "Matt Zumwalt".freeze]
  s.date = "2023-01-27"
  s.description = "Access controls for project hydra".freeze
  s.email = ["hydra-tech@googlegroups.com".freeze]
  s.homepage = "https://github.com/samvera/hydra-head/tree/master/hydra-access-controls".freeze
  s.licenses = ["APACHE-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Access controls for project hydra".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2", "< 7.1"])
  s.add_runtime_dependency(%q<active-fedora>.freeze, [">= 10.0.0"])
  s.add_runtime_dependency(%q<blacklight-access_controls>.freeze, ["~> 6.0"])
  s.add_runtime_dependency(%q<cancancan>.freeze, [">= 1.8", "< 4"])
  s.add_runtime_dependency(%q<deprecation>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 4.0"])
end
