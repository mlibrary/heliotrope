require 'spec_helper'

describe 'OIA-PMH Identify Request' do
  let(:xml) { Nokogiri::XML(response.body) }

  before do
    get '/catalog/oai?verb=Identify'
  end

  it "contains response date" do
    expect(Time.parse(xml.at_xpath('//xmlns:responseDate').text)).to be_within(5.seconds).of(Time.now)
  end

  it "contains repository name" do
    expect(xml.at_xpath('//xmlns:repositoryName').text).to eql 'Catalog Repository'
  end

  it "contains base url" do
    expect(xml.at_xpath('//xmlns:baseURL').text).to eql 'http://localhost/catalog/oai'
  end

  it "contains protocol version" do
    expect(xml.at_xpath('//xmlns:protocolVersion').text).to eql '2.0'
  end

  it "contains earliest datestamp" do
    expect(xml.at_xpath('//xmlns:earliestDatestamp').text).to eql '2014-02-03T18:42:53Z'
  end

  it "contains delete records" do
    expect(xml.at_xpath('//xmlns:deletedRecord').text).to eql 'persistent'
  end

  it "contains granularity" do
    expect(xml.at_xpath('//xmlns:granularity').text).to eql 'YYYY-MM-DDThh:mm:ssZ'
  end

  it "contains admin email" do
    expect(xml.at_xpath('//xmlns:adminEmail').text).to eql 'root@localhost'
  end

  it "contains repository prefix/identifier" do
    expect(
      xml.at_xpath('//oai-identifier:repositoryIdentifier', 'oai-identifier' => "http://www.openarchives.org/OAI/2.0/oai-identifier").text
    ).to eql 'test'
  end

  it "contains sample identifier" do
    expect(
      xml.at_xpath('//oai-identifier:sampleIdentifier', 'oai-identifier' => "http://www.openarchives.org/OAI/2.0/oai-identifier").text
    ).to eql 'oai:test:109660'
  end
end
