# -*- encoding: utf-8 -*-
# stub: dry-monads 1.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-monads".freeze
  s.version = "1.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-monads/issues", "changelog_uri" => "https://github.com/dry-rb/dry-monads/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-monads" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nikita Shilnikov".freeze]
  s.date = "2022-10-16"
  s.description = "Common monads for Ruby".freeze
  s.email = ["fg@flashgordon.ru".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-monads".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Common monads for Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 0.9", ">= 0.9"])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<dry-types>.freeze, [">= 0.1.2"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
