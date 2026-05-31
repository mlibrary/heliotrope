require 'minitest_helper'

describe 'Version' do
  it "has a version" do
    SimpleSolrClient::VERSION.wont_be_nil
  end
end
