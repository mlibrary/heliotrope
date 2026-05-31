# -*- encoding: utf-8 -*-
# stub: oai 1.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "oai".freeze
  s.version = "1.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ed Summers".freeze]
  s.autorequire = "oai".freeze
  s.date = "2022-04-29"
  s.email = "ehs@pobox.com".freeze
  s.executables = ["oai".freeze]
  s.files = ["bin/oai".freeze]
  s.homepage = "http://github.com/code4lib/ruby-oai".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A ruby library for working with the Open Archive Initiative Protocol for Metadata Harvesting (OAI-PMH)".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<builder>.freeze, [">= 3.1.0"])
  s.add_runtime_dependency(%q<faraday>.freeze, ["< 3"])
  s.add_runtime_dependency(%q<faraday-follow_redirects>.freeze, [">= 0.3.0", "< 2"])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 5.2.0", "< 7.1"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
end
