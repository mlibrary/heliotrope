# -*- encoding: utf-8 -*-
# stub: blacklight-access_controls 6.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "blacklight-access_controls".freeze
  s.version = "6.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Beer".freeze, "Justin Coyne".freeze, "Matt Zumwalt".freeze, "Valerie Maher".freeze]
  s.date = "2022-03-16"
  s.description = "Access controls for blacklight-based applications".freeze
  s.email = ["blacklight-development@googlegroups.com".freeze]
  s.homepage = "https://github.com/projectblacklight/blacklight-access_controls".freeze
  s.licenses = ["APACHE2".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Access controls for blacklight-based applications".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<blacklight>.freeze, ["> 6.0", "< 8"])
  s.add_runtime_dependency(%q<cancancan>.freeze, [">= 1.8"])
  s.add_runtime_dependency(%q<deprecation>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.2"])
  s.add_development_dependency(%q<factory_bot_rails>.freeze, ["~> 4.8"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.52.1"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
end
