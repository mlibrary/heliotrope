# -*- encoding: utf-8 -*-
# stub: yabeda-prometheus 0.9.1 ruby lib

Gem::Specification.new do |s|
  s.name = "yabeda-prometheus".freeze
  s.version = "0.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/yabeda-rb/yabeda-prometheus/blob/master/CHANGELOG.md", "homepage_uri" => "https://github.com/yabeda-rb/yabeda-prometheus", "source_code_uri" => "https://github.com/yabeda-rb/yabeda-prometheus" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrey Novikov".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-01-04"
  s.email = ["envek@envek.name".freeze]
  s.homepage = "https://github.com/yabeda-rb/yabeda-prometheus".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Extensible Prometheus exporter for your application".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<prometheus-client>.freeze, [">= 3.0", "< 5.0"])
  s.add_runtime_dependency(%q<yabeda>.freeze, ["~> 0.10"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
end
