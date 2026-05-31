# -*- encoding: utf-8 -*-
# stub: riiif 2.8.1 ruby lib

Gem::Specification.new do |s|
  s.name = "riiif".freeze
  s.version = "2.8.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze]
  s.date = "1980-01-02"
  s.description = "A IIIF image server".freeze
  s.email = ["jcoyne85@stanford.edu".freeze]
  s.homepage = "https://github.com/sul-dlss/riiif".freeze
  s.licenses = ["APACHE2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A Rails engine that support IIIF requests".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 4.2", "< 9"])
  s.add_runtime_dependency(%q<deprecation>.freeze, [">= 1.0.0"])
  s.add_runtime_dependency(%q<iiif-image-api>.freeze, [">= 0.1.0"])
  s.add_runtime_dependency(%q<ruby-vips>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
end
