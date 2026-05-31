require 'bundler/setup'
require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)

task ci: ['engine_cart:generate', :spec]
task default: :ci


task server: ['engine_cart:generate'] do
  within_test_app do
    system "bundle exec rails s"
  end
end
