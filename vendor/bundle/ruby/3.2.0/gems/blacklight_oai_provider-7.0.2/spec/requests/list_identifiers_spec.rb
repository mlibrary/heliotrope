require 'spec_helper'

describe 'OIA-PMH ListIdentifiers Request' do
  let(:xml) { Nokogiri::XML(response.body) }

  context 'for all documents' do
    before do
      get '/catalog/oai?verb=ListIdentifiers&metadataPrefix=oai_dc'
    end

    it 'returns 25 records' do
      expect(xml.xpath('//xmlns:ListIdentifiers/xmlns:header').count).to be 25
    end

    it 'first record has identifier and timestamp' do
      expect(xml.at_xpath('//xmlns:ListIdentifiers/xmlns:header/xmlns:identifier').text).not_to eql ''
      expect(xml.at_xpath('//xmlns:ListIdentifiers/xmlns:header/xmlns:datestamp').text).not_to eql ''
    end

    it 'contains resumptionToken' do
      expect(xml.at_xpath('//xmlns:resumptionToken').text).to eql 'oai_dc.f(2014-02-03T18:42:53Z).u(2015-02-03T18:42:53Z).t(30):25'
    end
  end

  context 'with resumption_token' do
    before do
      get '/catalog/oai?verb=ListIdentifiers&resumptionToken=oai_dc.f(2014-02-03T18:42:53Z).u(2014-03-03T18:42:53Z).t(30):25'
    end

    it 'returns 4 records' do
      expect(xml.xpath('//xmlns:ListIdentifiers/xmlns:header').count).to be 4
    end

    it 'first record has identifier and timestamp' do
      expect(xml.at_xpath('//xmlns:ListIdentifiers/xmlns:header/xmlns:identifier').text).not_to eql ''
      expect(xml.at_xpath('//xmlns:ListIdentifiers/xmlns:header/xmlns:datestamp').text).not_to eql ''
    end

    it 'does not contain a resumptionToken' do
      expect(xml.at_xpath('//xmlns:resumptionToken').text).to eql ''
    end
  end

  context 'for all documents within a time range' do
    before do
      get '/catalog/oai?verb=ListIdentifiers&metadataPrefix=oai_dc&from=2014-03-03&until=2014-04-03'
    end

    it 'returns 1 record' do
      expect(xml.xpath('//xmlns:ListIdentifiers/xmlns:header').count).to be 1
    end

    it 'does not contain a resumptionToken' do
      expect(xml.at_xpath('//xmlns:resumptionToken')).to be_nil
    end
  end

  context 'with different timestamp_field' do
    before :all do
      SolrDocument.timestamp_key = "record_creation_dtsi"
    end

    before do
      get '/catalog/oai?verb=ListIdentifiers&metadataPrefix=oai_dc&from=2015-01-01'
    end

    after :all do
      SolrDocument.timestamp_key = "timestamp"
    end

    it 'returns correct document' do
      expect(xml.xpath('//xmlns:ListIdentifiers/xmlns:header').count).to be 1
      expect(xml.at_xpath('//xmlns:ListIdentifiers/xmlns:header/xmlns:identifier').text).to eql 'oai:test:78908283'
    end

    it 'document displays correct timestamp' do
      expect(xml.at_xpath('//xmlns:ListIdentifiers/xmlns:header/xmlns:datestamp').text).to eql '2015-02-03T18:42:53Z'
    end
  end
end
