# frozen_string_literal: true

require 'rails_helper'

describe HandleService do
  subject { described_class }

  let(:invalidnoid) { 'invalidnoid' }
  let(:validnoid) { 'validnoid' }

  describe '#noid' do
    it { expect(subject.noid(nil)).to be nil }
    it { expect(subject.noid("http://authority/path")).to be nil }
    it { expect(subject.noid(subject.path(invalidnoid))).to eq nil }
    it { expect(subject.noid(subject.path(validnoid))).to eq validnoid }
    it { expect(subject.noid(subject.url(validnoid))).to eq validnoid }
    it { expect(subject.noid(subject.url(validnoid) + "?key=value")).to eq validnoid }
  end

  describe '#path' do
    it { expect(subject.path(nil)).to eq '2027/fulcrum.' }
    it { expect(subject.path(invalidnoid)).to eq "2027/fulcrum.#{invalidnoid}" }
    it { expect(subject.path(validnoid)).to eq "2027/fulcrum.#{validnoid}" }
  end

  describe '#url' do
    it { expect(subject.url(nil)).to eq "http://hdl.handle.net/#{subject.path(nil)}" }
    it { expect(subject.url(invalidnoid)).to eq "http://hdl.handle.net/#{subject.path(invalidnoid)}" }
    it { expect(subject.url(validnoid)).to eq "http://hdl.handle.net/#{subject.path(validnoid)}" }
  end

  describe '#value' do
    let(:response) { double('response') }
    let(:value) { double('value') }

    before do
      allow(HTTParty).to receive(:get).with("http://hdl.handle.net/api/handles/#{subject.path(validnoid)}").and_return(response)
      allow(response).to receive(:code).and_return(code)
      allow(response).to receive(:[]).with('responseCode').and_return(responseCode)
    end

    context '1 : Success. (HTTP 200 OK)' do
      let(:responseCode) { 1 }
      let(:code) { 200 }

      before do
        allow(response).to receive(:[]).with('values').and_return([{ "type" => "URL", "data" => { "value" => value } }])
      end

      it { expect(subject.value(validnoid)).to eq value }
    end

    context '2 : Error. Something unexpected went wrong during handle resolution. (HTTP 500 Internal Server Error)' do
      let(:responseCode) { 2 }
      let(:code) { 500 }

      it { expect(subject.value(validnoid)).to be nil }
    end

    context '100 : Handle Not Found. (HTTP 404 Not Found)' do
      let(:responseCode) { 100 }
      let(:code) { 404 }

      it { expect(subject.value(validnoid)).to be nil }
    end

    context '200 : Values Not Found. The handle exists but has no values (or no values according to the types and indices specified). (HTTP 200 OK)' do
      let(:responseCode) { 200 }
      let(:code) { 200 }

      it { expect(subject.value(validnoid)).to be nil }
    end
  end
end
