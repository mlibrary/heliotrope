# -*- encoding: utf-8 -*-
# stub: pragmatic_segmenter 0.3.23 ruby lib

Gem::Specification.new do |s|
  s.name = "pragmatic_segmenter".freeze
  s.version = "0.3.23"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kevin S. Dias".freeze]
  s.date = "2021-05-02"
  s.description = "Pragmatic Segmenter is a sentence segmentation tool for Ruby. It allows you to split a text into an array of sentences. This gem provides 2 main benefits over other segmentation gems - 1) It works well even with ill-formatted text 2) It works for multiple languages ".freeze
  s.email = ["diasks2@gmail.com".freeze]
  s.homepage = "https://github.com/diasks2/pragmatic_segmenter".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A rule-based sentence boundary detection gem that works out-of-the-box across many languages".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<unicode>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.7"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<stackprof>.freeze, [">= 0"])
end
