# -*- encoding: utf-8 -*-
# stub: resque-pool 0.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "resque-pool".freeze
  s.version = "0.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/resque/resque/blob/master/HISTORY.md", "homepage_uri" => "http://github.com/nevans/resque-pool", "source_code_uri" => "http://github.com/nevans/resque-pool" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["nicholas a. evans".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-01-08"
  s.description = "    quickly and easily fork a pool of resque workers,\n    saving memory (w/REE) and monitoring their uptime\n".freeze
  s.email = ["nick@ekenosen.net".freeze]
  s.executables = ["resque-pool".freeze]
  s.files = ["exe/resque-pool".freeze]
  s.homepage = "http://github.com/nevans/resque-pool".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "quickly and easily fork a pool of resque workers".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<resque>.freeze, [">= 1.22", "< 3"])
  s.add_runtime_dependency(%q<rake>.freeze, [">= 10.0", "< 14.0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8"])
  s.add_development_dependency(%q<cucumber>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<aruba>.freeze, ["~> 0.14.0"])
  s.add_development_dependency(%q<ronn>.freeze, [">= 0"])
  s.add_development_dependency(%q<mustache>.freeze, [">= 0"])
end
