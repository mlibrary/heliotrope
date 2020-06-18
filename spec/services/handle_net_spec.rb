# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleNet do
  let(:invalidnoid) { 'invalidnoid' }
  let(:validnoid) { 'validnoid' }

  describe '#noid' do
    it { expect(described_class.noid(nil)).to be nil }
    it { expect(described_class.noid(described_class::DOI_ORG_PREFIX + described_class::FULCRUM_HANDLE_PREFIX + invalidnoid)).to be nil }
    it { expect(described_class.noid(described_class::DOI_ORG_PREFIX + described_class::FULCRUM_HANDLE_PREFIX + validnoid)).to be nil }
    it { expect(described_class.noid(described_class::HANDLE_NET_PREFIX + described_class::FULCRUM_HANDLE_PREFIX + invalidnoid)).to be nil }
    it { expect(described_class.noid(described_class::HANDLE_NET_PREFIX + described_class::FULCRUM_HANDLE_PREFIX + validnoid)).to eq validnoid }
    it { expect(described_class.noid(described_class.path(invalidnoid))).to eq nil }
    it { expect(described_class.noid(described_class.path(validnoid))).to eq validnoid }
    it { expect(described_class.noid(described_class.url(validnoid))).to eq validnoid }
    it { expect(described_class.noid(described_class.url(validnoid) + "?key=value")).to eq validnoid }
  end

  describe '#path' do
    it { expect(described_class.path(nil)).to eq described_class::FULCRUM_HANDLE_PREFIX }
    it { expect(described_class.path(invalidnoid)).to eq described_class::FULCRUM_HANDLE_PREFIX + invalidnoid }
    it { expect(described_class.path(validnoid)).to eq described_class::FULCRUM_HANDLE_PREFIX + validnoid }
  end

  describe '#url' do
    it { expect(described_class.url(nil)).to eq described_class::HANDLE_NET_PREFIX + described_class.path(nil) }
    it { expect(described_class.url(invalidnoid)).to eq described_class::HANDLE_NET_PREFIX + described_class.path(invalidnoid) }
    it { expect(described_class.url(validnoid)).to eq described_class::HANDLE_NET_PREFIX + described_class.path(validnoid) }
  end

  describe 'Handle Service' do
    let(:noid) { validnoid }
    let(:url) { double('url') }

    it { expect(described_class.value(noid)).to be nil }
    it { expect(described_class.create_or_update(noid, url)).to be false }
    it { expect(described_class.delete(noid)).to be false }

    context 'instantiate' do
      let(:service) { instance_double(HandleService, 'service') }

      before do
        Settings.handle_service.instantiate = true
        allow(Services).to receive(:handle_service).and_return(service)
      end

      after { Settings.handle_service.instantiate = false }

      describe '#value' do
        subject { described_class.value(noid) }

        let(:handle) { instance_double(Handle, 'handle') }

        before do
          allow(service).to receive(:get).with(HandleNet.path(noid)).and_return(handle)
          allow(handle).to receive(:url).and_return(url)
        end

        it { is_expected.to be url }

        context 'not found' do
          before { allow(handle).to receive(:url).and_return(nil) }

          it { is_expected.to be nil }
        end

        context 'nil handle' do
          let(:handle) { nil }

          it { is_expected.to be nil }
        end
      end

      describe '#create_or_update' do
        subject { described_class.create_or_update(noid, url) }

        let(:handle) { instance_double(Handle, 'handle') }

        before do
          allow(Handle).to receive(:new).with(HandleNet.path(noid), url: url).and_return(handle)
          allow(service).to receive(:create).with(handle).and_return(true)
        end

        it { is_expected.to be true }

        context 'error' do
          let(:logger) { instance_double(Logger, 'logger') }
          let(:message) { "HandleNet.create_or_update(#{noid}, #{url}) failed with error #{error}" }
          let(:error) { 'error' }


          before do
            allow(Rails).to receive(:logger).and_return(logger)
            allow(logger).to receive(:error).with(message)
            allow(service).to receive(:create).with(handle).and_raise(error)
          end

          it do
            is_expected.to be false
            expect(logger).to have_received(:error).with(message)
          end
        end
      end

      describe '#delete' do
        subject { described_class.delete(noid) }

        before { allow(service).to receive(:delete).with(HandleNet.path(noid)).and_return(true) }

        it { is_expected.to be true }

        context 'non success' do
          before { allow(service).to receive(:delete).with(HandleNet.path(noid)).and_return(false) }

          it { is_expected.to be false }
        end
      end
    end
  end
end
