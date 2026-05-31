require 'spec_helper'

RSpec.describe SolrDocument do
  it 'includes BlacklightOaiProvider::SolrDocument' do
    expect(described_class.ancestors.include?(BlacklightOaiProvider::SolrDocument)).to be true
  end

  subject(:document) { described_class.new }

  describe '#timestamp' do
    it 'responds to timestamp' do
      expect(document).to respond_to :timestamp
    end

    it 'throws error if timestamp field not available' do
      expect {
        document.timestamp
      }.to raise_error BlacklightOaiProvider::Exceptions::MissingTimestamp
    end

    it 'returns timestamp' do
      doc = described_class.new({ timestamp: '2017-10-16T19:20:14Z' })
      expect(doc.timestamp).to be_a Time
      expect(doc.timestamp.xmlschema).to eql '2017-10-16T19:20:14Z'
    end
  end

  describe '#to_oai_dc' do
    let(:valid_xml) do
      '<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" '\
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ '\
      'http://www.openarchives.org/OAI/2.0/oai_dc.xsd"></oai_dc:dc>'
    end

    it 'responds to to_oai_dc' do
      expect(document).to respond_to :to_oai_dc
    end

    it "returns xml document" do
      expect(document.to_oai_dc).to eql valid_xml
    end
  end
end
