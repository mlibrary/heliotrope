# -*- encoding: utf-8 -*-
# stub: rspec-repeat 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-repeat".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rico Sta. Cruz".freeze]
  s.bindir = "exe".freeze
  s.date = "2015-09-24"
  s.description = "Retry an RSpec test until it succeeds".freeze
  s.email = ["rico@ricostacruz.com".freeze]
  s.homepage = "https://github.com/rstacruz/rspec-repeat".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Retry an RSpec test until it succeeds".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.10"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  s.add_runtime_dependency(%q<rspec>.freeze, ["~> 3.0"])
end
