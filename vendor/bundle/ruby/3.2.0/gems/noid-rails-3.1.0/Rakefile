# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'rubocop/rake_task'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

desc 'Run test suite'
task :spec do
  RSpec::Core::RakeTask.new
end

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

desc 'Continuous Integration (generate test app and run tests)'
task ci: ['rubocop', 'engine_cart:generate', 'spec']

task default: :ci
