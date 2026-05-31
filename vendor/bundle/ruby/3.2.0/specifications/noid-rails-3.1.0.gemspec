# -*- encoding: utf-8 -*-
# stub: noid-rails 3.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "noid-rails".freeze
  s.version = "3.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael J. Giarlo".freeze]
  s.date = "2023-01-13"
  s.description = "Noid identifier services for Rails-based applications.".freeze
  s.email = ["leftwing@alumni.rutgers.edu".freeze]
  s.homepage = "https://github.com/samvera/noid-rails".freeze
  s.licenses = ["Apache2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Noid identifier services for Rails-based applications".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5.0.0", "< 7.1"])
  s.add_runtime_dependency(%q<noid>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<bixby>.freeze, ["~> 5.0.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2.1"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.2"])
  s.add_development_dependency(%q<rake>.freeze, [">= 11"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
end
