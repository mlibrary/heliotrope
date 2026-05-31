# -*- encoding: utf-8 -*-
# stub: dropbox_api 0.1.21 ruby lib

Gem::Specification.new do |s|
  s.name = "dropbox_api".freeze
  s.version = "0.1.21"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jes\u00FAs Burgos".freeze]
  s.date = "2022-03-05"
  s.email = ["jburmac@gmail.com".freeze]
  s.homepage = "https://github.com/Jesus/dropbox_api".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Library for communicating with Dropbox API v2".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, ["< 3.0"])
  s.add_runtime_dependency(%q<oauth2>.freeze, ["~> 1.1"])
end
