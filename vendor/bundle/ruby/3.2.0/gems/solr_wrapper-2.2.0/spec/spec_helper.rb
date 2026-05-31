require 'coveralls'
Coveralls.wear!

require 'solr_wrapper'
require 'simple_solr_client'

require 'rspec'
require 'webmock/rspec'

WebMock.allow_net_connect!

FIXTURES_DIR = File.expand_path("fixtures", File.dirname(__FILE__))

RSpec.configure do |_config|
end
