# -*- encoding: utf-8 -*-
# stub: clamby 1.6.10 ruby lib

Gem::Specification.new do |s|
  s.name = "clamby".freeze
  s.version = "1.6.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["kobaltz".freeze]
  s.date = "2023-09-25"
  s.description = "Clamby allows users to scan files uploaded with Paperclip or Carrierwave. If a file has a virus, then you can delete this file and discard it without causing harm to other users.".freeze
  s.email = ["dave@k-innovations.net".freeze]
  s.homepage = "https://github.com/kobaltz/clamby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Scan file uploads with ClamAV".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
