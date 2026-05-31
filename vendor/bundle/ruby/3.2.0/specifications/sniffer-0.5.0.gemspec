# -*- encoding: utf-8 -*-
# stub: sniffer 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sniffer".freeze
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrey Deryabin".freeze]
  s.date = "2022-05-06"
  s.description = "Analyze HTTP Requests".freeze
  s.email = ["aderyabin@evilmartians.com".freeze]
  s.homepage = "http://github.com/aderyabin/sniffer".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Analyze HTTP Requests".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<anyway_config>.freeze, [">= 1.0"])
  s.add_runtime_dependency(%q<dry-initializer>.freeze, ["~> 3"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<sinatra>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<puma>.freeze, [">= 3.10.0"])
  s.add_development_dependency(%q<httpclient>.freeze, [">= 2.8.3"])
  s.add_development_dependency(%q<http>.freeze, [">= 3.0.0"])
  s.add_development_dependency(%q<patron>.freeze, [">= 0.10.0"])
  s.add_development_dependency(%q<curb>.freeze, [">= 0.9.4"])
  s.add_development_dependency(%q<ethon>.freeze, [">= 0.11.0"])
  s.add_development_dependency(%q<typhoeus>.freeze, [">= 0.9.0"])
  s.add_development_dependency(%q<em-http-request>.freeze, [">= 1.1.0"])
  s.add_development_dependency(%q<excon>.freeze, [">= 0.60.0"])
end
