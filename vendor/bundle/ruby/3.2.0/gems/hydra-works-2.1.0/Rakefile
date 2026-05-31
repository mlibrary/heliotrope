require 'bundler/gem_tasks'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'active_fedora/rake_support'

namespace :works do
  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end

  RSpec::Core::RakeTask.new(:rspec)

  desc 'Start up Solr & FCRepo and run the test suite'
  task :spec do
    with_test_server do
      Rake::Task['works:rspec'].invoke
    end
  end
end

desc 'Spin up Solr & Fedora and run the test suite'
task ci: ['works:rubocop', 'works:spec']

task default: :ci
