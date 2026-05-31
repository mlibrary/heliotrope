begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require 'rubocop/rake_task'
require 'solr_wrapper'
require 'solr_wrapper/rake_task'
require 'engine_cart/rake_task'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task default: 'ci'

def solr_config_dir
  File.join(__dir__, 'solr_conf', 'conf')
end

namespace :solr do
  desc 'Run test suite (with solr wrapper)'
  task :spec do
    SolrWrapper.wrap do |solr|
      solr.with_collection(name: 'blacklight-core', dir: solr_config_dir) do # |collection_name|
        Rake::Task['spec'].invoke
      end
    end
  end
end

desc 'Run CI build'
task ci: ['rubocop', 'engine_cart:generate', 'solr:spec']

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end
