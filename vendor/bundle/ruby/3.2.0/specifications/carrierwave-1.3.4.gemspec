# -*- encoding: utf-8 -*-
# stub: carrierwave 1.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = "carrierwave".freeze
  s.version = "1.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jonas Nicklas".freeze]
  s.date = "2023-09-24"
  s.description = "Upload files in your Ruby applications, map them to a range of ORMs, store them on different backends.".freeze
  s.email = ["jonas.nicklas@gmail.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/carrierwaveuploader/carrierwave".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Ruby file upload library".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0.0"])
  s.add_runtime_dependency(%q<activemodel>.freeze, [">= 4.0.0"])
  s.add_runtime_dependency(%q<mime-types>.freeze, [">= 1.16"])
  s.add_runtime_dependency(%q<ssrf_filter>.freeze, ["< 1.1.0", "~> 1.0"])
  s.add_development_dependency(%q<rails>.freeze, [">= 5.0.0"])
  s.add_development_dependency(%q<cucumber>.freeze, ["~> 2.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
  s.add_development_dependency(%q<fog-core>.freeze, ["~> 2.1.0"])
  s.add_development_dependency(%q<fog-aws>.freeze, [">= 0"])
  s.add_development_dependency(%q<fog-google>.freeze, [">= 0"])
  s.add_development_dependency(%q<fog-local>.freeze, [">= 0"])
  s.add_development_dependency(%q<fog-rackspace>.freeze, [">= 0"])
  s.add_development_dependency(%q<mini_magick>.freeze, [">= 3.6.0"])
  s.add_development_dependency(%q<rmagick>.freeze, [">= 2.16"])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0"])
  s.add_development_dependency(%q<generator_spec>.freeze, [">= 0.9.1"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
end
