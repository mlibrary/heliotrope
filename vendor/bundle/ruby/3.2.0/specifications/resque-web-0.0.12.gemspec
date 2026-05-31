# -*- encoding: utf-8 -*-
# stub: resque-web 0.0.12 ruby lib

Gem::Specification.new do |s|
  s.name = "resque-web".freeze
  s.version = "0.0.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tony Arcieri".freeze]
  s.date = "2017-09-27"
  s.description = "A Rails-based frontend to the Resque job queue system.".freeze
  s.email = ["tony.arcieri@gmail.com".freeze]
  s.homepage = "https://github.com/resque/resque-web".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Rails-based Resque web interface".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<resque>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<twitter-bootstrap-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<font-awesome-sass>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<jquery-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<sass-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<coffee-rails>.freeze, [">= 0"])
end
