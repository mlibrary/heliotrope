# -*- encoding: utf-8 -*-
# stub: spring 2.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "spring".freeze
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jon Leighton".freeze]
  s.date = "2020-08-25"
  s.description = "Preloads your application so things like console, rake and tests run faster".freeze
  s.email = ["j@jonathanleighton.com".freeze]
  s.executables = ["spring".freeze]
  s.files = ["bin/spring".freeze]
  s.homepage = "https://github.com/rails/spring".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Rails application preloader".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<bump>.freeze, [">= 0"])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
end
