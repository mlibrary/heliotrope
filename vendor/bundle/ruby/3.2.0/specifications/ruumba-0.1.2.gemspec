# -*- encoding: utf-8 -*-
# stub: ruumba 0.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "ruumba".freeze
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric Weinstein".freeze, "Jan Biniok".freeze, "Yvan Barth\u00E9lemy".freeze]
  s.date = "2017-07-11"
  s.description = "RuboCop linting for ERB templates.".freeze
  s.email = "eric.q.weinstein@gmail.com".freeze
  s.executables = ["ruumba".freeze]
  s.files = ["bin/ruumba".freeze]
  s.homepage = "https://github.com/ericqweinstein/ruumba".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Allows users to lint Ruby code in ERB templates the same way they lint source code (using RuboCop).".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rubocop>.freeze, [">= 0"])
end
