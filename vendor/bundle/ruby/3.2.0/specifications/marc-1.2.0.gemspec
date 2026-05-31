# -*- encoding: utf-8 -*-
# stub: marc 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "marc".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kevin Clarke".freeze, "Bill Dueber".freeze, "William Groppe".freeze, "Jonathan Rochkind".freeze, "Ross Singer".freeze, "Ed Summers".freeze, "Chris Beer".freeze]
  s.date = "2022-08-02"
  s.email = "ehs@pobox.com".freeze
  s.executables = ["marc".freeze, "marc2xml".freeze]
  s.files = ["bin/marc".freeze, "bin/marc2xml".freeze]
  s.homepage = "https://github.com/ruby-marc/ruby-marc/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A ruby library for working with Machine Readable Cataloging".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<standard>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<scrub_rb>.freeze, [">= 1.0.1", "< 2"])
  s.add_runtime_dependency(%q<unf>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rexml>.freeze, [">= 0"])
end
