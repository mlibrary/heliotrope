# -*- encoding: utf-8 -*-
# stub: yabeda-activejob 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "yabeda-activejob".freeze
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/Fullscript/yabeda-activejob/CHANGELOG.md", "homepage_uri" => "https://github.com/Fullscript/yabeda-activejob", "source_code_uri" => "https://github.com/Fullscript/yabeda-activejob" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fullscript".freeze]
  s.date = "2023-11-01"
  s.description = "Prometheus exporter for collecting metrics around your activejobs".freeze
  s.email = ["josh.etsenake@fullscript.com".freeze]
  s.homepage = "https://github.com/Fullscript/yabeda-activejob".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Yabeda Prometheus exporter for monitoring your activejobs".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 5.2"])
  s.add_runtime_dependency(%q<yabeda>.freeze, ["~> 0.6"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 6.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21"])
end
