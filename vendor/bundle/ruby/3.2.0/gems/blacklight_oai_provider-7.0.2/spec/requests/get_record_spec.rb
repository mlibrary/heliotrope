require 'spec_helper'

describe 'OIA-PMH GetRecord Request' do
  let(:xml) { Nokogiri::XML(response.body) }
  let(:namespaces) do
    {
      dc: 'http://purl.org/dc/elements/1.1/',
      xmlns: 'http://www.openarchives.org/OAI/2.0/',
      oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    }
  end

  before do
    get '/catalog/oai?verb=GetRecord&identifier=oai:test:2007020969&metadataPrefix=oai_dc'
  end

  it 'contains identifier' do
    expect(xml.at_xpath('//xmlns:GetRecord/xmlns:record/xmlns:header/xmlns:identifier').text).to eql 'oai:test:2007020969'
  end

  it 'contains datestamp' do
    expect(xml.at_xpath('//xmlns:GetRecord/xmlns:record/xmlns:header/xmlns:datestamp').text).to eql '2014-02-03T18:42:53Z'
  end

  it 'contains sets' do
    expect(xml.at_xpath('//xmlns:GetRecord/xmlns:record/xmlns:header/xmlns:setSpec').text).to eql 'language:English'
  end

  it 'contains creator' do
    expect(xml.at_xpath('//xmlns:metadata/oai_dc:dc/dc:creator', namespaces).text).to eql 'Hearth, Amy Hill, 1958-'
  end

  it 'contains date' do
    expect(xml.at_xpath('//xmlns:metadata/oai_dc:dc/dc:date', namespaces).text).to eql '2008'
  end

  it 'contains subjects' do
    nodes = xml.xpath('//xmlns:metadata/oai_dc:dc/dc:subject', namespaces)
    expect(nodes.count).to be 4
    expect(nodes.map(&:text)).to match_array ['Strong Medicine, 1922-', 'Delaware women', 'Indian women shamans', 'Delaware Indians']
  end

  it 'contains title' do
    expect(xml.at_xpath('//xmlns:metadata/oai_dc:dc/dc:title', namespaces).text).to eql '"Strong Medicine speaks"'
  end

  it 'contains language' do
    expect(xml.at_xpath('//xmlns:metadata/oai_dc:dc/dc:language', namespaces).text).to eql 'English'
  end

  it 'contains format' do
    expect(xml.at_xpath('//xmlns:metadata/oai_dc:dc/dc:format', namespaces).text).to eql 'Book'
  end

  context 'when identifier has slashes' do
    before do
      get '/catalog/oai?verb=GetRecord&identifier=oai:test:fe/gh/00313831&metadataPrefix=oai_dc'
    end

    it 'retrieves record' do
      expect(xml.at_xpath('//xmlns:GetRecord/xmlns:record/xmlns:header/xmlns:identifier').text).to eql 'oai:test:fe/gh/00313831'
    end
  end
end
