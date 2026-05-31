# -*- encoding: utf-8 -*-
# stub: rspec-context-private 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-context-private".freeze
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sean Devine".freeze]
  s.date = "2014-05-24"
  s.description = "RSpec shared context to make private methods temporarily public.".freeze
  s.email = ["barelyknown@icloud.com".freeze]
  s.homepage = "https://github.com/barelyknown/rspec-context-private".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "RSpec shared context to make private methods temporarily public.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
