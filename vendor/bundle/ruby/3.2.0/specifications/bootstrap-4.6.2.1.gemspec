# -*- encoding: utf-8 -*-
# stub: bootstrap 4.6.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "bootstrap".freeze
  s.version = "4.6.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Twitter, Inc.".freeze]
  s.date = "2024-08-24"
  s.email = "glex.spb@gmail.com".freeze
  s.homepage = "https://github.com/twbs/bootstrap-rubygem".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "The most popular HTML, CSS, and JavaScript framework for developing responsive, mobile first projects on the web. http://getbootstrap.com".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<popper_js>.freeze, [">= 1.16.1", "< 2"])
  s.add_runtime_dependency(%q<autoprefixer-rails>.freeze, [">= 9.1.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.8.0"])
  s.add_development_dependency(%q<minitest-reporters>.freeze, ["~> 1.0.5"])
  s.add_development_dependency(%q<term-ansicolor>.freeze, [">= 0"])
  s.add_development_dependency(%q<capybara>.freeze, [">= 2.6.0"])
  s.add_development_dependency(%q<cuprite>.freeze, [">= 0"])
  s.add_development_dependency(%q<actionpack>.freeze, [">= 4.1.5"])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 4.1.5"])
  s.add_development_dependency(%q<json>.freeze, [">= 1.8.1"])
  s.add_development_dependency(%q<sprockets-rails>.freeze, [">= 2.3.2"])
  s.add_development_dependency(%q<jquery-rails>.freeze, [">= 3.1.0"])
  s.add_development_dependency(%q<slim-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<uglifier>.freeze, [">= 0"])
end
