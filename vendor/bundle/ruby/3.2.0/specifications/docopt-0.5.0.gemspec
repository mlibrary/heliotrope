# -*- encoding: utf-8 -*-
# stub: docopt 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "docopt".freeze
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Blake Williams".freeze, "Vladimir Keleshev".freeze, "Alex Speller".freeze, "Nima Johari".freeze]
  s.date = "2012-09-01"
  s.description = "Isn't it awesome how `optparse` and other option parsers generate help and usage-messages based on your code?! Hell no!\nYou know what's awesome? It's when the option parser *is* generated based on the help and usage-message that you write in a docstring! That's what docopt does!".freeze
  s.email = "code@shabbyrobe.org".freeze
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://github.com/docopt/docopt.rb".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A command line option parser, that will make you smile.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 2

  s.add_development_dependency(%q<json>.freeze, ["~> 1.6.5"])
end
