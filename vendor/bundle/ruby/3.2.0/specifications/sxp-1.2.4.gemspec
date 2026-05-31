# -*- encoding: utf-8 -*-
# stub: sxp 1.2.4 ruby lib

Gem::Specification.new do |s|
  s.name = "sxp".freeze
  s.version = "1.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/dryruby/sxp/issues", "documentation_uri" => "https://dryruby.github.io/sxp", "homepage_uri" => "https://github.com/dryruby/sxp", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/dryruby/sxp" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arto Bendiken".freeze, "Gregg Kellogg".freeze]
  s.date = "2023-05-03"
  s.description = "Universal S-expression parser with specific support for Common Lisp, Scheme, and RDF/SPARQL".freeze
  s.email = ["arto@bendiken.net".freeze, "gregg@greggkellogg.net".freeze]
  s.executables = ["sxp2rdf".freeze, "sxp2json".freeze, "sxp2xml".freeze, "sxp2yaml".freeze]
  s.files = ["bin/sxp2json".freeze, "bin/sxp2rdf".freeze, "bin/sxp2xml".freeze, "bin/sxp2yaml".freeze]
  s.homepage = "https://github.com/dryruby/sxp/".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A pure-Ruby implementation of a universal S-expression parser.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<matrix>.freeze, ["~> 0.4"])
  s.add_development_dependency(%q<amazing_print>.freeze, ["~> 1.4"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
