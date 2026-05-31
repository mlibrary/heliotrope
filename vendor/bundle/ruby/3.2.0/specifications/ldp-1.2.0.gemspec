# -*- encoding: utf-8 -*-
# stub: ldp 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ldp".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Beer".freeze]
  s.date = "2023-01-27"
  s.description = "Linked Data Platform client library".freeze
  s.email = ["chris@cbeer.info".freeze]
  s.executables = ["ldp".freeze]
  s.files = ["bin/ldp".freeze]
  s.homepage = "https://github.com/samvera/ldp".freeze
  s.licenses = ["APACHE2".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Linked Data Platform client library".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<deprecation>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1"])
  s.add_runtime_dependency(%q<http_logger>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<json-ld>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<rdf-isomorphic>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rdf-ldp>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rdf-turtle>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rdf-vocab>.freeze, [">= 0.8"])
  s.add_runtime_dependency(%q<slop>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<capybara_discoball>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls_reborn>.freeze, [">= 0"])
  s.add_development_dependency(%q<github_changelog_generator>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
  s.add_development_dependency(%q<webrick>.freeze, [">= 0"])
end
