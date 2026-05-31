# -*- encoding: utf-8 -*-
# stub: scrub_rb 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "scrub_rb".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jonathan Rochkind".freeze]
  s.date = "2014-09-16"
  s.email = ["jonathan@dnil.net".freeze]
  s.homepage = "https://github.com/jrochkind/scrub_rb".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Pure-ruby polyfill of MRI 2.1 String#scrub, for ruby 1.9 and 2.0 any interpreter".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
