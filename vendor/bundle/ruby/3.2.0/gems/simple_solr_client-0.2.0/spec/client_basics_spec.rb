require 'minitest_helper'

describe SimpleSolrClient::Client do

  before do
    @client = TestClient.instance.client
  end
  it "creates a new object" do
    @client.base_url.must_equal 'http://localhost:8983/solr'
  end

  it "strips off a trailing slash for base_url" do
    c = SimpleSolrClient::Client.new('http://localhost:8983/solr/')
    c.base_url.must_equal 'http://localhost:8983/solr'
  end

  it "constructs a url with no args" do
    @client.url.must_equal 'http://localhost:8983/solr'
  end

  it "constructs a URL with args" do
    @client.url('admin', 'ping').must_equal 'http://localhost:8983/solr/admin/ping'
  end


end
