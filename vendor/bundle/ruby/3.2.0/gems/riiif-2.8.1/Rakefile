require 'bundler/gem_tasks'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

require 'engine_cart/rake_task'
task ci: [:rubocop, 'engine_cart:generate'] do
  Rake::Task['spec'].invoke
end

task default: :ci
