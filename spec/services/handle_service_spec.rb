# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleService do
  subject { described_class }

  let(:invalidnoid) { 'invalidnoid' }
  let(:validnoid) { 'validnoid' }

  describe '#noid' do
    it { expect(subject.noid(nil)).to be nil }
    it { expect(subject.noid(described_class::HANDLE_NET_API_HANDLES + invalidnoid)).to be nil }
    it { expect(subject.noid(subject.path(invalidnoid))).to eq nil }
    it { expect(subject.noid(subject.path(validnoid))).to eq validnoid }
    it { expect(subject.noid(subject.url(validnoid))).to eq validnoid }
    it { expect(subject.noid(subject.url(validnoid) + "?key=value")).to eq validnoid }
  end

  describe '#path' do
    it { expect(subject.path(nil)).to eq described_class::FULCRUM_PREFIX }
    it { expect(subject.path(invalidnoid)).to eq described_class::FULCRUM_PREFIX + invalidnoid }
    it { expect(subject.path(validnoid)).to eq described_class::FULCRUM_PREFIX + validnoid }
  end

  describe '#url' do
    it { expect(subject.url(nil)).to eq described_class::HANDLE_NET_PREFIX + subject.path(nil) }
    it { expect(subject.url(invalidnoid)).to eq described_class::HANDLE_NET_PREFIX + subject.path(invalidnoid) }
    it { expect(subject.url(validnoid)).to eq described_class::HANDLE_NET_PREFIX + subject.path(validnoid) }
  end

  describe '#value' do
    let(:response) { double('response') }
    let(:body) { { responseCode: code, values: values }.to_json }
    let(:values) { [] }

    before do
      allow(Faraday).to receive(:get).with(described_class::HANDLE_NET_API_HANDLES + described_class.path(validnoid)).and_return(response)
      allow(response).to receive(:body).and_return(body)
      allow(response).to receive(:status).and_return(status)
    end

    context '1' do
      let(:code) { 1 }
      let(:values) { [{ data: { value: 'url' }, type: 'URL' }] }
      let(:status) { 200 }

      it { expect(described_class.value(validnoid)).to eq "url" }
    end

    context '1 : Success. (HTTP 200 OK)' do
      let(:code) { 1 }
      let(:values) { [{ data: { value: 'doi' }, type: 'DOI' }] }
      let(:status) { 200 }

      it { expect(described_class.value(validnoid)).to eq "1 : Success. (HTTP 200 OK)" }
    end

    context '2' do
      let(:code) { 2 }
      let(:status) { 500 }

      it { expect(described_class.value(validnoid)).to eq "2 : Error. Something unexpected went wrong during handle resolution. (HTTP 500 Internal Server Error)" }
    end

    context '100' do
      let(:code) { 100 }
      let(:status) { 404 }

      it { expect(described_class.value(validnoid)).to eq "100 : Handle Not Found. (HTTP 404 Not Found)" }
    end

    context '200' do
      let(:code) { 200 }
      let(:status) { 200 }

      it { expect(described_class.value(validnoid)).to eq "200 : Values Not Found. The handle exists but has no values (or no values according to the types and indices specified). (HTTP 200 OK)" }
    end
  end
end
