# -*- encoding: utf-8 -*-
# stub: bagit 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "bagit".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tom Johnson, Francesco Lazzarino, Jamie Little".freeze]
  s.date = "2024-09-17"
  s.description = "Ruby Library and Command Line tools for bagit".freeze
  s.email = "jamie@jamielittle.org".freeze
  s.executables = ["bagit".freeze]
  s.files = ["bin/bagit".freeze]
  s.homepage = "http://github.com/tipr/bagit".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.0".freeze, "< 3.4".freeze])
  s.rubygems_version = "3.4.20".freeze
  s.summary = "BagIt package generation and validation".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<validatable>.freeze, ["~> 1.6"])
  s.add_runtime_dependency(%q<docopt>.freeze, ["~> 0.5.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3"])
  s.add_development_dependency(%q<standard>.freeze, [">= 0"])
end
