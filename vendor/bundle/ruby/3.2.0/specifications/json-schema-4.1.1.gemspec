# -*- encoding: utf-8 -*-
# stub: json-schema 4.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "json-schema".freeze
  s.version = "4.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 2.5".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kenny Hoxworth".freeze, "Vox Pupuli".freeze]
  s.date = "2023-09-15"
  s.email = "voxpupuli@groups.io".freeze
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE.md".freeze]
  s.files = ["LICENSE.md".freeze, "README.md".freeze]
  s.homepage = "http://github.com/voxpupuli/json-schema/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Ruby JSON Schema Validator".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<addressable>.freeze, [">= 2.8"])
end
