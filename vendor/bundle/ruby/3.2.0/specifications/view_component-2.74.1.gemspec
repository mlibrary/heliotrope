# -*- encoding: utf-8 -*-
# stub: view_component 2.74.1 ruby lib

Gem::Specification.new do |s|
  s.name = "view_component".freeze
  s.version = "2.74.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/ViewComponent/view_component/blob/main/docs/CHANGELOG.md", "source_code_uri" => "https://github.com/viewcomponent/view_component" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["ViewComponent Team".freeze]
  s.date = "2022-10-10"
  s.homepage = "https://viewcomponent.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A framework for building reusable, testable & encapsulated view components in Ruby on Rails.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.0.0", "< 8.0"])
  s.add_runtime_dependency(%q<method_source>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.4"])
  s.add_development_dependency(%q<benchmark-ips>.freeze, ["~> 2.8.2"])
  s.add_development_dependency(%q<better_html>.freeze, ["~> 1"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2"])
  s.add_development_dependency(%q<erb_lint>.freeze, ["~> 0.0.37"])
  s.add_development_dependency(%q<haml>.freeze, ["~> 5"])
  s.add_development_dependency(%q<jbuilder>.freeze, ["~> 2"])
  s.add_development_dependency(%q<m>.freeze, ["~> 1"])
  s.add_development_dependency(%q<minitest>.freeze, ["= 5.6.0"])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.13"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.18.0"])
  s.add_development_dependency(%q<simplecov-console>.freeze, ["~> 0.7.2"])
  s.add_development_dependency(%q<slim>.freeze, ["~> 4.0"])
  s.add_development_dependency(%q<sprockets-rails>.freeze, ["~> 3.2.2"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.25"])
  s.add_development_dependency(%q<yard-activesupport-concern>.freeze, ["~> 0.0.1"])
end
