# -*- encoding: utf-8 -*-
# stub: hyrax 4.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hyrax".freeze
  s.version = "4.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Coyne".freeze, "Michael J. Giarlo".freeze, "Carolyn Cole".freeze, "Matt Zumwalt".freeze, "Jeremy Friesen".freeze, "Trey Pendragon".freeze, "Esm\u00E9 Cowles".freeze]
  s.date = "2023-05-30"
  s.description = "Hyrax is a featureful Samvera front-end based on the latest and greatest Samvera software components.".freeze
  s.email = ["jcoyne85@stanford.edu".freeze, "mjgiarlo@stanford.edu".freeze, "cam156@psu.edu".freeze, "matt@databindery.com".freeze, "jeremy.n.friesen@gmail.com".freeze, "tpendragon@princeton.edu".freeze, "escowles@ticklefish.org".freeze]
  s.executables = ["db-migrate-seed.sh".freeze, "db-wait.sh".freeze, "hyrax-entrypoint.sh".freeze, "solrcloud-assign-configset.sh".freeze, "solrcloud-upload-configset.sh".freeze]
  s.files = ["bin/db-migrate-seed.sh".freeze, "bin/db-wait.sh".freeze, "bin/hyrax-entrypoint.sh".freeze, "bin/solrcloud-assign-configset.sh".freeze, "bin/solrcloud-upload-configset.sh".freeze]
  s.homepage = "http://github.com/samvera/hyrax".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Hyrax is a front-end based on the robust Samvera framework, providing a user interface for common repository features. Hyrax offers the ability to create repository object types on demand, to deposit content via multiple workflows, and to describe content with flexible metadata. Numerous optional features may be turned on in the administrative dashboard or added through plugins.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, ["~> 6.0"])
  s.add_runtime_dependency(%q<active-fedora>.freeze, ["~> 14.0"])
  s.add_runtime_dependency(%q<almond-rails>.freeze, ["~> 0.1"])
  s.add_runtime_dependency(%q<awesome_nested_set>.freeze, ["~> 3.1"])
  s.add_runtime_dependency(%q<blacklight>.freeze, ["~> 7.29"])
  s.add_runtime_dependency(%q<blacklight-gallery>.freeze, ["~> 4.0"])
  s.add_runtime_dependency(%q<breadcrumbs_on_rails>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<browse-everything>.freeze, [">= 0.16", "< 2.0"])
  s.add_runtime_dependency(%q<carrierwave>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<clipboard-rails>.freeze, ["~> 1.5"])
  s.add_runtime_dependency(%q<connection_pool>.freeze, ["~> 2.4"])
  s.add_runtime_dependency(%q<draper>.freeze, ["~> 4.0"])
  s.add_runtime_dependency(%q<dry-events>.freeze, ["~> 0.2.0"])
  s.add_runtime_dependency(%q<dry-equalizer>.freeze, ["~> 0.2"])
  s.add_runtime_dependency(%q<dry-monads>.freeze, ["~> 1.5"])
  s.add_runtime_dependency(%q<dry-struct>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<dry-validation>.freeze, ["~> 1.3"])
  s.add_runtime_dependency(%q<flipflop>.freeze, ["~> 2.3"])
  s.add_runtime_dependency(%q<flot-rails>.freeze, ["~> 0.0.6"])
  s.add_runtime_dependency(%q<font-awesome-rails>.freeze, ["~> 4.2"])
  s.add_runtime_dependency(%q<hydra-derivatives>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<hydra-editor>.freeze, ["~> 6.0"])
  s.add_runtime_dependency(%q<hydra-file_characterization>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<hydra-head>.freeze, ["~> 12.0"])
  s.add_runtime_dependency(%q<hydra-works>.freeze, [">= 0.16"])
  s.add_runtime_dependency(%q<iiif_manifest>.freeze, [">= 0.3", "< 2.0"])
  s.add_runtime_dependency(%q<json-schema>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<legato>.freeze, ["~> 0.3"])
  s.add_runtime_dependency(%q<linkeddata>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<mailboxer>.freeze, ["~> 0.12"])
  s.add_runtime_dependency(%q<nest>.freeze, ["~> 3.1"])
  s.add_runtime_dependency(%q<noid-rails>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<oauth>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<oauth2>.freeze, ["~> 1.2"])
  s.add_runtime_dependency(%q<openseadragon>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<posix-spawn>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<qa>.freeze, ["~> 5.5", ">= 5.5.1"])
  s.add_runtime_dependency(%q<rails_autolink>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<rdf-rdfxml>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rdf-vocab>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<redis>.freeze, ["~> 4.0"])
  s.add_runtime_dependency(%q<redis-namespace>.freeze, ["~> 1.5"])
  s.add_runtime_dependency(%q<redlock>.freeze, [">= 0.1.2", "< 2.0"])
  s.add_runtime_dependency(%q<reform>.freeze, ["~> 2.3"])
  s.add_runtime_dependency(%q<reform-rails>.freeze, ["~> 0.2.0"])
  s.add_runtime_dependency(%q<retriable>.freeze, [">= 2.9", "< 4.0"])
  s.add_runtime_dependency(%q<signet>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<tinymce-rails>.freeze, ["~> 5.10"])
  s.add_runtime_dependency(%q<valkyrie>.freeze, ["~> 3.0.1"])
  s.add_runtime_dependency(%q<view_component>.freeze, ["~> 2.74.1"])
  s.add_runtime_dependency(%q<sprockets>.freeze, ["~> 3.7"])
  s.add_runtime_dependency(%q<sass-rails>.freeze, ["~> 6.0"])
  s.add_runtime_dependency(%q<select2-rails>.freeze, ["~> 3.5"])
  s.add_development_dependency(%q<capybara>.freeze, ["~> 3.29"])
  s.add_development_dependency(%q<capybara-screenshot>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<database_cleaner>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<engine_cart>.freeze, ["~> 2.5"])
  s.add_development_dependency(%q<equivalent-xml>.freeze, ["~> 0.5"])
  s.add_development_dependency(%q<factory_bot>.freeze, ["~> 4.4"])
  s.add_development_dependency(%q<fcrepo_wrapper>.freeze, ["~> 0.5", ">= 0.5.1"])
  s.add_development_dependency(%q<mida>.freeze, ["~> 0.3"])
  s.add_development_dependency(%q<okcomputer>.freeze, [">= 0"])
  s.add_development_dependency(%q<pg>.freeze, ["~> 1.2"])
  s.add_development_dependency(%q<rspec-activemodel-mocks>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<selenium-webdriver>.freeze, ["~> 4.4"])
  s.add_development_dependency(%q<i18n-debug>.freeze, [">= 0"])
  s.add_development_dependency(%q<i18n_yaml_sorter>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails-controller-testing>.freeze, ["~> 1"])
  s.add_development_dependency(%q<bixby>.freeze, ["~> 5.0", ">= 5.0.2"])
  s.add_development_dependency(%q<shoulda-callback-matchers>.freeze, ["~> 1.1.1"])
  s.add_development_dependency(%q<shoulda-matchers>.freeze, ["~> 3.1"])
  s.add_development_dependency(%q<webdrivers>.freeze, ["~> 4.4"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
end
