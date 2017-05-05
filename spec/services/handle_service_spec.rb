# frozen_string_literal: true

require 'rails_helper'

describe HandleService do
  context 'nil argument' do
    it { expect(described_class.handle?(nil)).to eq false }
    it { expect(described_class.handle(nil)).to eq nil }
    it { expect(described_class.url(nil)).to eq nil }
    it { expect(described_class.object(nil)).to eq nil }
  end

  context 'invalid object' do
    let(:object) { double("object") }
    it { expect(described_class.handle?(object)).to eq false }
    it { expect(described_class.handle(object)).to eq nil }
    it { expect(described_class.url(object)).to eq nil }
  end

  context 'invalid handle' do
    it { expect(described_class.object(double("handle"))).to eq nil }
    it { expect(described_class.object("handle")).to eq nil }
  end

  context 'valid object' do
    let(:noid) { 'noid' }
    let(:handle) { "2027/fulcrum.#{noid}" }
    let(:url) { "http://hdl.handle.net/#{handle}" }
    let(:object) { double("object") }

    before do
      allow(ActiveFedora::Base).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
      allow(ActiveFedora::Base).to receive(:find).with(noid).and_return(object)
      allow(object).to receive(:id).and_return(noid)
    end

    context 'without assigned handle' do
      it { expect(described_class.handle?(object)).to eq true }
      it { expect(described_class.handle(object)).to eq handle }
      it { expect(described_class.url(object)).to eq url }
      it { expect(described_class.object(handle)).to eq object }
      it { expect(described_class.object(url)).to eq object }
    end

    context 'with assigned handle' do
      let(:hdl) { 'hdl' }
      let(:handle) { "2027/fulcrum.#{hdl}" }
      let(:response) { double("response") }

      before do
        allow(object).to receive(:hdl).and_return(hdl)
        allow(HTTParty).to receive(:get).and_return(response)
        allow(response).to receive(:code).and_return(code)
        allow(response).to receive(:[]).with('responseCode').and_return(responseCode)
      end

      context '1 : Success. (HTTP 200 OK)' do
        let(:responseCode) { 1 }
        let(:code) { 200 }

        before do
          allow(response).to receive(:[]).with('values').and_return([{ "type" => "URL", "data" => { "value" => "https:/fulcrum.org/concern/file_sets/#{handle_noid}" } }])
        end

        context 'valid handle noid' do
          let(:handle_noid) { noid }
          it { expect(described_class.handle?(object)).to eq true }
          it { expect(described_class.handle(object)).to eq handle }
          it { expect(described_class.url(object)).to eq url }
          it { expect(described_class.object(handle)).to eq object }
          it { expect(described_class.object(url)).to eq object }
        end

        context 'invalid handle noid' do
          let(:handle_noid) { 'stale_noid' }
          it { expect(described_class.handle?(object)).to eq true }
          it { expect(described_class.handle(object)).to eq handle }
          it { expect(described_class.url(object)).to eq url }
          it { expect { described_class.object(handle) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
          it { expect { described_class.object(url) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
        end
      end

      context '2 : Error. Something unexpected went wrong during handle resolution. (HTTP 500 Internal Server Error)' do
        let(:responseCode) { 2 }
        let(:code) { 500 }
        it { expect(described_class.handle?(object)).to eq true }
        it { expect(described_class.handle(object)).to eq handle }
        it { expect(described_class.url(object)).to eq url }
        it { expect { described_class.object(handle) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
        it { expect { described_class.object(url) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
      end

      context '100 : Handle Not Found. (HTTP 404 Not Found)' do
        let(:responseCode) { 100 }
        let(:code) { 404 }
        it { expect(described_class.handle?(object)).to eq true }
        it { expect(described_class.handle(object)).to eq handle }
        it { expect(described_class.url(object)).to eq url }
        it { expect { described_class.object(handle) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
        it { expect { described_class.object(url) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
      end

      context '200 : Values Not Found. The handle exists but has no values (or no values according to the types and indices specified). (HTTP 200 OK)' do
        let(:responseCode) { 200 }
        let(:code) { 200 }
        it { expect(described_class.handle?(object)).to eq true }
        it { expect(described_class.handle(object)).to eq handle }
        it { expect(described_class.url(object)).to eq url }
        it { expect { described_class.object(handle) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
        it { expect { described_class.object(url) }.to raise_error(ActiveFedora::ObjectNotFoundError) }
      end
    end
  end
end
