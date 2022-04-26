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
    it { expect(described_class.service).to be nil }

    context 'instantiate' do
      let(:handle_service) { instance_double(HandleRest::HandleService, 'handle_service') }
      let(:service) { instance_double(HandleRest::Service, 'service') }
      let(:admin_group) { HandleRest::Identity.from_s("200:0.NA/2027") }
      let(:admin_group_value) { HandleRest::AdminValue.new(admin_group.index, HandleRest::AdminPermissionSet.new, admin_group.handle) }
      let(:admin_group_value_line) { HandleRest::ValueLine.new(100, admin_group_value) }
      let(:url_service) { instance_double(HandleRest::UrlService, 'url_service') }

      before do
        Settings.handle_service.instantiate = true
        allow(Services).to receive(:handle_service).and_return(handle_service)
        allow(HandleRest::Service).to receive(:new).with([admin_group_value_line], handle_service).and_return(service)
        allow(HandleRest::UrlService).to receive(:new).with(1, service).and_return(url_service)
      end

      after { Settings.handle_service.instantiate = false }

      describe '#value' do
        subject { described_class.value(noid) }

        before { allow(url_service).to receive(:get).with(HandleNet.path(noid)).and_return(url) }

        it { is_expected.to be url }

        context 'error' do
          let(:logger) { instance_double(Logger, 'logger') }
          let(:message) { "HandleNet.value(#{noid}) failed with error #{error}" }
          let(:error) { 'error' }

          before do
            allow(Rails).to receive(:logger).and_return(logger)
            allow(logger).to receive(:error).with(message)
            allow(url_service).to receive(:get).with(HandleNet.path(noid)).and_raise(error)
          end

          it do
            is_expected.to be nil
            expect(logger).to have_received(:error).with(message)
          end
        end
      end

      describe '#create_or_update' do
        subject { described_class.create_or_update(noid, url) }

        before { allow(url_service).to receive(:set).with(HandleNet.path(noid), url).and_return(url) }

        it { is_expected.to be true }

        context 'error' do
          let(:logger) { instance_double(Logger, 'logger') }
          let(:message) { "HandleNet.create_or_update(#{noid}, #{url}) failed with error #{error}" }
          let(:error) { 'error' }

          before do
            allow(Rails).to receive(:logger).and_return(logger)
            allow(logger).to receive(:error).with(message)
            allow(url_service).to receive(:set).with(HandleNet.path(noid), url).and_raise(error)
          end

          it do
            is_expected.to be false
            expect(logger).to have_received(:error).with(message)
          end
        end
      end

      describe '#delete' do
        subject { described_class.delete(noid) }

        before { allow(service).to receive(:delete).with(HandleRest::Handle.from_s(HandleNet.path(noid))).and_return([]) }

        it { is_expected.to be true }

        context 'error' do
          let(:logger) { instance_double(Logger, 'logger') }
          let(:message) { "HandleNet.delete(#{noid}) failed with error #{error}" }
          let(:error) { 'error' }

          before do
            allow(Rails).to receive(:logger).and_return(logger)
            allow(logger).to receive(:error).with(message)
            allow(service).to receive(:delete).with(HandleRest::Handle.from_s(HandleNet.path(noid))).and_raise(error)
          end

          it do
            is_expected.to be false
            expect(logger).to have_received(:error).with(message)
          end
        end
      end

      describe '#service' do
        subject { described_class.service }

        it { is_expected.to be service }
      end
    end
  end
end
