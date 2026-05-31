# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flot/rails/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "flot-rails"
  s.version     = Flot::Rails::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Vasily Fedoseyev"]
  s.email       = ["vasilyfedoseyev@gmail.com"]
  s.homepage    = "https://github.com/Vasfed/flot-rails"
  s.summary     = "jQuery Flot for Rails Asset pipeline"
  s.description = "Provides easy installation and usage of jQuery-flot javascript library for your Rails 3.1+ application."
  s.license     = "MIT"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "jquery-rails"
  s.add_development_dependency "rails",   ">= 3.1"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").select{|f| f =~ /^bin/}
  s.require_path = 'lib'
end
