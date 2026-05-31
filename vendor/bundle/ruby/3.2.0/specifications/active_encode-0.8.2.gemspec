# -*- encoding: utf-8 -*-
# stub: active_encode 0.8.2 ruby lib

Gem::Specification.new do |s|
  s.name = "active_encode".freeze
  s.version = "0.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Klein, Chris Colvard, Phuong Dinh".freeze]
  s.date = "2021-09-26"
  s.description = "This gem provides an interface to transcoding services such as Ffmpeg, Amazon Elastic Transcoder, or Zencoder.".freeze
  s.email = ["mbklein@gmail.com, chris.colvard@gmail.com, phuongdh@gmail.com".freeze]
  s.homepage = "https://github.com/samvera-labs/active_encode".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Declare encode job classes that can be run by a variety of encoding services".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<aws-sdk-cloudwatchevents>.freeze, [">= 0"])
  s.add_development_dependency(%q<aws-sdk-cloudwatchlogs>.freeze, [">= 0"])
  s.add_development_dependency(%q<aws-sdk-elastictranscoder>.freeze, [">= 0"])
  s.add_development_dependency(%q<aws-sdk-mediaconvert>.freeze, [">= 0"])
  s.add_development_dependency(%q<aws-sdk-s3>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, ["~> 1.0.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.2"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<sprockets>.freeze, ["< 4"])
end
