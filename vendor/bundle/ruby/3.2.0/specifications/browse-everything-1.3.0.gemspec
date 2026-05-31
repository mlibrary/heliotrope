# -*- encoding: utf-8 -*-
# stub: browse-everything 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "browse-everything".freeze
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Carolyn Cole".freeze, "Jessie Keck".freeze, "Michael B. Klein".freeze, "Thomas Scherz".freeze, "Xiaoming Wang".freeze, "Jeremy Friesen".freeze]
  s.date = "2023-11-09"
  s.description = "AJAX/Rails engine file browser for cloud storage services".freeze
  s.email = ["cam156@psu.edu".freeze, "jkeck@stanford.edu".freeze, "mbklein@gmail.com".freeze, "scherztc@ucmail.uc.edu".freeze, "xw5d@virginia.edu".freeze, "jeremy.n.friesen@gmail.com".freeze]
  s.homepage = "https://github.com/projecthydra/browse-everything".freeze
  s.licenses = ["Apache 2".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "AJAX/Rails engine file browser for cloud storage services".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.5"])
  s.add_runtime_dependency(%q<aws-sdk-s3>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<dropbox_api>.freeze, [">= 0.1.20"])
  s.add_runtime_dependency(%q<google-apis-drive_v3>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<googleauth>.freeze, [">= 0.6.6", "< 2.0"])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 4.2", "< 7.2"])
  s.add_runtime_dependency(%q<ruby-box>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<signet>.freeze, ["~> 0.8"])
  s.add_runtime_dependency(%q<typhoeus>.freeze, [">= 0"])
  s.add_development_dependency(%q<bixby>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<bootstrap>.freeze, ["~> 4.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.3"])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
  s.add_development_dependency(%q<factory_bot_rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<jquery-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<puma>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails-controller-testing>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<sass-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<selenium-webdriver>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<turbolinks>.freeze, [">= 0"])
  s.add_development_dependency(%q<webdrivers>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
end
