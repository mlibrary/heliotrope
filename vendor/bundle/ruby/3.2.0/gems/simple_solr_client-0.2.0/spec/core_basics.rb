require 'minitest_helper'

describe SimpleSolrClient::Client do

  before do
    @core = TempCore.instance.core('core_basics')
  end
  it "creates a new object" do
    @core.base_url.must_equal "http://localhost:8983/solr"
  end

  it "constructs a url with no args" do
    @core.url.must_equal "http://localhost:8983/solr/#{@core.name}"
  end

  it "constructs a URL with args" do
    @core.url('admin', 'ping').must_equal "http://localhost:8983/solr/#{@core.name}/admin/ping"
  end


end
