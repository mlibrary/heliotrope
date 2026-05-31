# -*- encoding: utf-8 -*-
# stub: nest 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "nest".freeze
  s.version = "3.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michel Martens".freeze]
  s.date = "2019-11-06"
  s.description = "It is a design pattern in key-value databases to use the key to simulate structure, and Nest can take care of that.".freeze
  s.email = ["michel@soveran.com".freeze]
  s.homepage = "http://github.com/soveran/nest".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Object-oriented keys for Redis.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redic>.freeze, [">= 0"])
  s.add_development_dependency(%q<cutest>.freeze, [">= 0"])
end
