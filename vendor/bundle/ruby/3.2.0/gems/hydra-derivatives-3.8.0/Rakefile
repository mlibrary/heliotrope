#!/usr/bin/env rake

require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'solr_wrapper/rake_task'
require 'fcrepo_wrapper'
require 'active_fedora/rake_support'
require 'rubocop/rake_task'

namespace :derivatives do
  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end

  RSpec::Core::RakeTask.new(:rspec) do |task|
    task.rspec_opts = "--tag ~requires_kdu_compress" if ENV['CI']
  end

  desc 'Start up Solr & Fedora and run tests'
  task :spec do
    with_test_server do
      Rake::Task['derivatives:rspec'].invoke
    end
  end

  desc 'Start up test server'
  task :test_server do
    ENV["RAILS_ENV"] = "test"
    with_test_server do
      puts "Solr: http://localhost:#{ENV["SOLR_TEST_PORT"]}/solr"
      puts "Fedora: http://localhost:#{ENV["FCREPO_TEST_PORT"]}/rest"
      while(1) do
        sleep(1)
      end
    end
  end
end

desc 'Run continuous integration build'
task ci: ['derivatives:rubocop', 'derivatives:spec']

task default: :ci
