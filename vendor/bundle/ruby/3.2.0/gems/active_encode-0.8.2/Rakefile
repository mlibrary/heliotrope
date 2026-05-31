# frozen_string_literal: true

require 'rake/clean'
require 'bundler'
require 'rubocop/rake_task'
require 'engine_cart/rake_task'

Bundler::GemHelper.install_tasks

desc "CI build"
task ci: ["active_encode:ci"]
desc "Rspec"
task spec: ["active_encode:ci"]

task default: [:ci]

namespace 'active_encode' do
  task 'environment' do
    ENV['environment'] = 'test'
  end

  desc "Check style guidelines"
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end

  desc "CI build"
  task ci: [:rubocop, "active_encode:environment", "engine_cart:generate", "active_encode:spec"]

  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end
