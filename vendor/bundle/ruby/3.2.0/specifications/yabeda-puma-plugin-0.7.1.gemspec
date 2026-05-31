# -*- encoding: utf-8 -*-
# stub: yabeda-puma-plugin 0.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "yabeda-puma-plugin".freeze
  s.version = "0.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Salahutdinov Dmitry".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-11-28"
  s.description = "Extends Yabeda metrics with puma web server values by using puma plugin".freeze
  s.email = ["dsalahutdinov@gmail.com".freeze]
  s.homepage = "http://github.com/yabeda-rb/yabeda-puma-plugin".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Puma web server plugin for collecting puma metrics with Yabeda framework.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<yabeda>.freeze, ["~> 0.5"])
  s.add_runtime_dependency(%q<puma>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rack>.freeze, ["< 3"])
  s.add_development_dependency(%q<yabeda-prometheus>.freeze, ["~> 0.8"])
end
