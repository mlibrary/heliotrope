require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec'
require 'rspec/core/rake_task'

desc 'Default: run specs.'
task default: :spec

RSpec::Core::RakeTask.new do |t|
  if ENV['COVERAGE'] && RUBY_VERSION =~ /^1.8/
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec', '--exclude', 'gems']
  end
end

# Use yard to build docs
begin
  require 'yard'
  require 'yard/rake/yardoc_task'
  project_root = File.expand_path(File.dirname(__FILE__))
  doc_destination = File.join(project_root, 'doc')

  YARD::Rake::YardocTask.new(:doc) do |yt|
    yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) +
      [File.join(project_root, 'README.md')]
    yt.options = ['--output-dir', doc_destination, '--readme', 'README.md']
  end
rescue LoadError
  desc 'Generate YARD Documentation'
  task :doc do
    abort 'Please install the YARD gem to generate rdoc.'
  end
end
