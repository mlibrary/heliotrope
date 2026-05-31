# -*- encoding: utf-8 -*-
# stub: hydra-derivatives 3.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hydra-derivatives".freeze
  s.version = "3.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze]
  s.date = "2023-02-08"
  s.description = "Derivative generation plugin for hydra".freeze
  s.email = ["jenlindner@gmail.com".freeze, "jcoyne85@stanford.edu".freeze]
  s.homepage = "https://github.com/projecthydra/hydra-derivatives".freeze
  s.licenses = ["APACHE2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Derivative generation plugin for hydra".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.1"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, ["~> 0.2"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails>.freeze, ["> 5.1", "< 7.1"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<active_encode>.freeze, ["~> 0.1"])
  s.add_runtime_dependency(%q<active-fedora>.freeze, [">= 14.0"])
  s.add_runtime_dependency(%q<active-triples>.freeze, [">= 1.2"])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0", "< 7.1"])
  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.5"])
  s.add_runtime_dependency(%q<deprecation>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<mime-types>.freeze, ["> 2.0", "< 4.0"])
  s.add_runtime_dependency(%q<mini_magick>.freeze, [">= 3.2", "< 5"])
end
