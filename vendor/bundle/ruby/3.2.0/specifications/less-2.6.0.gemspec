# -*- encoding: utf-8 -*-
# stub: less 2.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "less".freeze
  s.version = "2.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Charles Lowell".freeze]
  s.date = "2014-06-03"
  s.description = "Invoke the Less CSS compiler from Ruby".freeze
  s.email = ["cowboyd@thefrontside.net".freeze]
  s.executables = ["lessc".freeze]
  s.files = ["bin/lessc".freeze]
  s.homepage = "http://lesscss.org".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Leaner CSS, in your browser or Ruby (via less.js)".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<commonjs>.freeze, ["~> 0.2.7"])
end
