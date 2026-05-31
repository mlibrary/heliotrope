# -*- encoding: utf-8 -*-
# stub: yabeda-rails 0.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "yabeda-rails".freeze
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrey Novikov".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-08-03"
  s.description = "Easy collecting your Rails apps metrics".freeze
  s.email = ["envek@envek.name".freeze]
  s.homepage = "https://github.com/yabeda-rb/yabeda-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Extensible metrics for monitoring Ruby on Rails application".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<anyway_config>.freeze, [">= 1.3", "< 3"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<yabeda>.freeze, ["~> 0.8"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
end
