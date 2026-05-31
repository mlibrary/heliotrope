# -*- encoding: utf-8 -*-
# stub: redic 1.5.3 ruby lib

Gem::Specification.new do |s|
  s.name = "redic".freeze
  s.version = "1.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michel Martens".freeze, "Cyril David".freeze]
  s.date = "2019-08-09"
  s.description = "Lightweight Redis Client".freeze
  s.email = ["michel@soveran.com".freeze, "cyx@cyx.is".freeze]
  s.homepage = "https://github.com/amakawa/redic".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Lightweight Redis Client".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<hiredis>.freeze, [">= 0"])
end
