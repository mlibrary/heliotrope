require 'rake'
require 'bundler'

Bundler::GemHelper.install_tasks

require 'engine_cart/rake_task'
require 'solr_wrapper'

task default: [:rubocop, :ci]

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

desc 'Run test suite'
task ci: ['engine_cart:generate'] do
  SolrWrapper.wrap do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(__dir__), "solr", "conf")) do
      within_test_app do
        system "RAILS_ENV=test rake blacklight_oai_provider:index:seed"
      end
      Rake::Task['spec'].invoke
    end
  end
end
