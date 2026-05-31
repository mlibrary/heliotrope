# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

load "lib/tasks/migrate.rake"

task default: :spec

task :docs do
  sh %( bin/yard )
  sh %( cd docs && make html )
end
