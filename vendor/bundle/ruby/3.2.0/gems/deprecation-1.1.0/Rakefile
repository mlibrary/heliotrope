require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'


begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec


task :console do
  sh "irb -rubygems -I lib -r deprecation.rb"
end
