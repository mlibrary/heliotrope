require 'spec_helper'

describe Ldp::Resource::BinarySource do
  let(:client) { instance_double(Ldp::Client) }
  let(:uri) { 'http://example.com/foo/bar' }
  let(:content) { 'somecontent' }
  let(:instance) { described_class.new(client, uri, content) }

  describe "#inspect" do
    subject { instance.inspect }

    it "does not display content" do
      expect(subject).to match /subject=\"http:\/\/example\.com\/foo\/bar\"/
      expect(subject).not_to match /somecontent/
    end
  end

  describe '#described_by' do
    subject { instance.described_by }
    context 'without a description' do
      before do
        allow(client).to receive(:head).and_return(instance_double(Ldp::Response, links: { }))
      end

      it 'retrieves the description object' do
        expect(subject).to eq nil
      end
    end

    context 'with a description' do
      before do
        allow(client).to receive(:head).and_return(instance_double(Ldp::Response, links: { 'describedby' => ['http://example.com/foo/bar/desc']}))
        allow(client).to receive(:find_or_initialize).with('http://example.com/foo/bar/desc').and_return(desc)
      end

      let(:desc) { double }

      it 'retrieves the description object' do
        expect(subject).to eq desc
      end
    end
  end

  describe "#content" do
    context "when an Ldp::Response is passed in" do
      let(:mock_response) { instance_double(Faraday::Response, headers: {}, env: { url: "info:a" }) }
      let(:content) { Ldp::Response.new(mock_response) }
      let(:client) { instance_double(Ldp::Client, get: double(body: 'retrieved value')) }
      
      subject { instance.content }

      it { is_expected.to eq 'retrieved value' }
    end
  end
end
