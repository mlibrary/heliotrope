# -*- encoding: utf-8 -*-
# stub: posix-spawn 0.3.15 ruby lib
# stub: ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "posix-spawn".freeze
  s.version = "0.3.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Tomayko".freeze, "Aman Gupta".freeze]
  s.date = "2020-07-14"
  s.description = "posix-spawn uses posix_spawnp(2) for faster process spawning".freeze
  s.email = ["r@tomayko.com".freeze, "aman@tmm1.net".freeze]
  s.executables = ["posix-spawn-benchmark".freeze]
  s.extensions = ["ext/extconf.rb".freeze]
  s.extra_rdoc_files = ["COPYING".freeze, "HACKING".freeze]
  s.files = ["COPYING".freeze, "HACKING".freeze, "bin/posix-spawn-benchmark".freeze, "ext/extconf.rb".freeze]
  s.homepage = "https://github.com/rtomayko/posix-spawn".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "posix_spawnp(2) for ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake-compiler>.freeze, ["= 0.7.6"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 4"])
end
