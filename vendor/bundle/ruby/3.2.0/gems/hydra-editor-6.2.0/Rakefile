#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'HydraEditor'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'solr_wrapper/rake_task'
require 'fcrepo_wrapper'
require 'active_fedora/rake_support'
require 'engine_cart/rake_task'

task :setup_test_server do
  require 'engine_cart'
  EngineCart.load_application!
end

desc 'Continuous Integration'
task ci: ['engine_cart:generate'] do
  ENV['environment'] = "test"
  with_test_server do
    Rake::Task['spec'].invoke
  end
end

task default: :ci
