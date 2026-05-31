# -*- encoding: utf-8 -*-
# stub: flipflop 2.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "flipflop".freeze
  s.version = "2.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul Annesley".freeze, "Rolf Timmermans".freeze, "Jippe Holwerda".freeze]
  s.date = "2023-03-31"
  s.description = "Declarative API for specifying features, switchable in declaration, database and cookies.".freeze
  s.email = ["paul@annesley.cc".freeze, "rolftimmermans@voormedia.com".freeze, "jippeholwerda@voormedia.com".freeze]
  s.homepage = "https://github.com/voormedia/flipflop".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A feature flipflopper for Rails web applications.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0"])
  s.add_runtime_dependency(%q<terminal-table>.freeze, [">= 1.8"])
end
