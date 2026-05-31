# -*- encoding: utf-8 -*-
# stub: iiif_manifest 1.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "iiif_manifest".freeze
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze, "Trey Pendragon".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-02-21"
  s.description = "IIIF http://iiif.io/ defines an API for presenting related images in a viewer. This transforms Hydra::Works objects into that format usable by players such as http://universalviewer.io/".freeze
  s.email = ["jcoyne@justincoyne.com".freeze]
  s.homepage = "https://github.com/samvera/iiif_manifest".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Generate IIIF presentation manifests for Hydra::Works".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4"])
  s.add_development_dependency(%q<bixby>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
end
