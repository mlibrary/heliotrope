require 'spec_helper'

describe SolrWrapper::Client do
  subject { described_class.new('http://localhost:8983/solr/') }

  describe '#exists?' do
    it 'checks if a solrcloud collection exists' do
      stub_request(:get, 'http://localhost:8983/solr/admin/collections?action=LIST&wt=json').to_return(body: '{ "collections": ["x", "y", "z"]}')
      stub_request(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=a').to_return(body: '{ "status": { "a": {} } }')

      expect(subject.exists?('x')).to eq true
      expect(subject.exists?('a')).to eq false
    end

    it 'checks if a solr core exists' do
      stub_request(:get, 'http://localhost:8983/solr/admin/collections?action=LIST&wt=json').to_return(body: '{ "error": { "msg": "Solr instance is not running in SolrCloud mode."} }')

      stub_request(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=x').to_return(body: '{ "status": { "x": { "name": "x" } } }')
      stub_request(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=a').to_return(body: '{ "status": { "a": {} } }')

      expect(subject.exists?('x')).to eq true
      expect(subject.exists?('a')).to eq false
    end
  end
end
