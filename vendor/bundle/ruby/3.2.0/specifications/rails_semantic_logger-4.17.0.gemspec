# -*- encoding: utf-8 -*-
# stub: rails_semantic_logger 4.17.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_semantic_logger".freeze
  s.version = "4.17.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/reidmorrison/rails_semantic_logger/issues", "documentation_uri" => "https://logger.rocketjob.io", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/reidmorrison/rails_semantic_logger/tree/v4.17.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Reid Morrison".freeze]
  s.date = "2024-07-05"
  s.homepage = "https://logger.rocketjob.io".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Feature rich logging framework that replaces the Rails logger.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.1"])
  s.add_runtime_dependency(%q<semantic_logger>.freeze, ["~> 4.16"])
end
