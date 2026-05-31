# -*- encoding: utf-8 -*-
# stub: yabeda 0.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "yabeda".freeze
  s.version = "0.12.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrey Novikov".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-07-28"
  s.description = "Collect statistics about how your application is performing with ease. Export metrics to various monitoring systems.\n".freeze
  s.email = ["envek@envek.name".freeze]
  s.homepage = "https://github.com/yabeda-rb/yabeda".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Extensible framework for collecting metric for your Ruby application".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<anyway_config>.freeze, [">= 1.0", "< 3"])
  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<dry-initializer>.freeze, [">= 0"])
end
