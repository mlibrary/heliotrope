require 'bundler/gem_tasks'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'rubocop/rake_task'
require 'active_fedora/rake_support'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end

desc 'Run test suite'
task :spec do
  RSpec::Core::RakeTask.new(:spec)
end

desc 'Spin up test servers and run specs'
task :spec_with_app_load do
  with_test_server do
    Rake::Task['spec'].invoke
  end
end

desc 'Spin up Solr & Fedora and run the test suite'
task ci: :rubocop do
  Rake::Task['spec_with_app_load'].invoke
end

desc 'Start up test server'
task :test_server do
  ENV["RAILS_ENV"] = "test"
  with_test_server do
    puts "Solr: http://localhost:#{ENV['SOLR_TEST_PORT']}/solr"
    puts "Fedora: http://localhost:#{ENV['FCREPO_TEST_PORT']}/rest"
    loop do
      sleep(1)
    end
  end
end

task default: :ci
