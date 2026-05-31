# -*- encoding: utf-8 -*-
# stub: valkyrie 3.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "valkyrie".freeze
  s.version = "3.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Trey Pendragon".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-05-15"
  s.email = ["tpendragon@princeton.edu".freeze]
  s.homepage = "https://github.com/samvera/valkyrie".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "An ORM using the Data Mapper pattern, specifically built to solve Digital Repository use cases.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<dry-struct>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<activemodel>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<dry-types>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.0", ">= 3.0.10"])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<reform>.freeze, ["~> 2.2"])
  s.add_runtime_dependency(%q<reform-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<json-ld>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rdf-vocab>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.9", "!= 2.0.0", "< 3"])
  s.add_runtime_dependency(%q<faraday-multipart>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, ["> 1.16.0", "< 3"])
  s.add_development_dependency(%q<rake>.freeze, [">= 10"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<solr_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, [">= 0"])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
end
