# -*- encoding: utf-8 -*-
# stub: dry-container 0.11.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-container".freeze
  s.version = "0.11.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-container/issues", "changelog_uri" => "https://github.com/dry-rb/dry-container/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-container" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andy Holland".freeze]
  s.date = "2022-09-16"
  s.description = "A simple, configurable object container implemented in Ruby".freeze
  s.email = ["andyholland1991@aol.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-container".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A simple, configurable object container implemented in Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
