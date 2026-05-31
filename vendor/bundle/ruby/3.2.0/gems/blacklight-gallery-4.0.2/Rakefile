require "bundler/gem_tasks"

APP_ROOT = File.dirname(__FILE__)

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

desc "Load fixtures"
task :fixtures => ['engine_cart:generate'] do
  within_test_app do
      system "rake blacklight:index:seed RAILS_ENV=test"
      abort "Error running fixtures" unless $?.success?
  end
end

desc "Execute Continuous Integration build"
task :ci => ['engine_cart:generate'] do

  require 'solr_wrapper'
  SolrWrapper.wrap(port: '8983') do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), 'solr', 'conf')) do
      Rake::Task['fixtures'].invoke
      Rake::Task['spec'].invoke
    end
  end
end


desc "Run Solr and Blacklight for interactive development"
task :server do
  require 'solr_wrapper'
  SolrWrapper.wrap(port: '8983') do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), 'solr', 'conf')) do
      within_test_app do
        system "rake blacklight:index:seed"
        system "bundle exec rails s"
      end
    end
  end
end
