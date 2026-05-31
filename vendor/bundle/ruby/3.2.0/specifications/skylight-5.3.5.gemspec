# -*- encoding: utf-8 -*-
# stub: skylight 5.3.5 ruby lib
# stub: ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "skylight".freeze
  s.version = "5.3.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tilde, Inc.".freeze]
  s.date = "2024-01-18"
  s.email = ["engineering@tilde.io".freeze]
  s.executables = ["skylight".freeze]
  s.extensions = ["ext/extconf.rb".freeze]
  s.files = ["bin/skylight".freeze, "ext/extconf.rb".freeze]
  s.homepage = "https://www.skylight.io".freeze
  s.licenses = ["Nonstandard".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Skylight is a smart profiler for Rails, Sinatra, and other Ruby apps.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2.0"])
  s.add_development_dependency(%q<beefcake>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.17.3"])
  s.add_development_dependency(%q<puma>.freeze, [">= 0"])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0.1"])
  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.2.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
  s.add_development_dependency(%q<rspec-collection_matchers>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.31.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21.2"])
  s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
end
