# -*- encoding: utf-8 -*-
# stub: hydra-file_characterization 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-file_characterization".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Treacy".freeze, "Jeremy Friesen".freeze, "Sue Richeson".freeze, "Rajesh Balekai".freeze]
  s.date = "2023-02-01"
  s.description = "To provide a wrapper for file characterization".freeze
  s.email = ["jatr@kb.dk".freeze, "jeremy.n.friesen@gmail.com".freeze, "spr7b@virginia.edu".freeze, "rbalekai@gmail.com".freeze]
  s.homepage = "https://github.com/projecthydra/hydra-file_characterization".freeze
  s.licenses = ["APACHE2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "To provide a wrapper for file characterization".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.0.0"])
  s.add_development_dependency(%q<bixby>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<github_changelog_generator>.freeze, [">= 0"])
  s.add_development_dependency(%q<guard>.freeze, [">= 0"])
  s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
end
