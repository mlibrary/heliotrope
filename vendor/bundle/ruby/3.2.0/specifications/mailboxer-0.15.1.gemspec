# -*- encoding: utf-8 -*-
# stub: mailboxer 0.15.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mailboxer".freeze
  s.version = "0.15.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eduardo Casanova Cuesta".freeze]
  s.date = "2017-05-18"
  s.description = "A Rails engine that allows any model to act as messageable, adding the ability to exchange messages with any other messageable model, even different ones. It supports the use of conversations with two or more recipients to organize the messages. You have a complete use of a mailbox object for each messageable model that manages an inbox, sentbox and trash for conversations. It also supports sending notifications to messageable models, intended to be used as system notifications.".freeze
  s.email = "ecasanovac@gmail.com".freeze
  s.homepage = "https://github.com/ging/mailboxer".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Messaging system for rails apps.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 5.0.0"])
  s.add_runtime_dependency(%q<carrierwave>.freeze, [">= 0.5.8"])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<rspec-collection_matchers>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 1.0.0"])
  s.add_development_dependency(%q<shoulda-matchers>.freeze, ["~> 2"])
  s.add_development_dependency(%q<factory_girl>.freeze, ["~> 2.6.0"])
  s.add_development_dependency(%q<forgery>.freeze, [">= 0.3.6"])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0.3.9"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
end
