$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'ldpath'
require 'rdf/reasoner'
require 'webmock/rspec'

require 'simplecov'
require 'coveralls'
require 'byebug' unless ENV['TRAVIS']

RDF::Reasoner.apply(:rdfs)
RDF::Reasoner.apply(:owl)

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start('rails') do
  add_filter '/.internal_test_app'
  add_filter '/lib/generators'
  add_filter '/spec'
  add_filter '/tasks'
  add_filter '/lib/qa/version.rb'
  add_filter '/lib/qa/engine.rb'
end
SimpleCov.command_name 'spec'
Coveralls.wear!

def webmock_fixture(fixture)
  File.new File.expand_path(File.join("../fixtures", fixture), __FILE__)
end

# returns the file contents
def load_fixture_file(fname)
  File.open(Rails.root.join('spec', 'fixtures', fname)) do |f|
    return f.read
  end
end
