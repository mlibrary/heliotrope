require 'spec_helper'

describe 'OIA-PMH ListMetadataFormats Request' do
  let(:xml) { Nokogiri::XML(response.body) }

  context 'without identifier parameter' do
    before do
      get '/catalog/oai?verb=ListMetadataFormats'
    end

    it 'contains oai_dc schema' do
      expect(xml.at_xpath('//xmlns:ListMetadataFormats/xmlns:metadataFormat/xmlns:schema').text).to eql 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
    end

    it 'contains oai_dc metadataPrefix' do
      expect(xml.at_xpath('//xmlns:ListMetadataFormats/xmlns:metadataFormat/xmlns:metadataPrefix').text).to eql 'oai_dc'

    end

    it 'contains oai_dc metadataNamespace' do
      expect(xml.at_xpath('//xmlns:ListMetadataFormats/xmlns:metadataFormat/xmlns:metadataNamespace').text).to eql 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    end
  end

  context 'with identifier parameter' do
    before do
      get '/catalog/oai?verb=ListMetadataFormats&identifier=oai:test:2007020969'
    end

    it 'contains oai_dc schema' do
      expect(xml.at_xpath('//xmlns:ListMetadataFormats/xmlns:metadataFormat/xmlns:schema').text).to eql 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
    end

    it 'contains oai_dc metadataPrefix' do
      expect(xml.at_xpath('//xmlns:ListMetadataFormats/xmlns:metadataFormat/xmlns:metadataPrefix').text).to eql 'oai_dc'

    end

    it 'contains oai_dc metadataNamespace' do
      expect(xml.at_xpath('//xmlns:ListMetadataFormats/xmlns:metadataFormat/xmlns:metadataNamespace').text).to eql 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    end
  end
end
