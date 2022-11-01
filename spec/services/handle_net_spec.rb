# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleNet do
  let(:invalidnoid) { 'invalidnoid' }
  let(:validnoid) { 'validnoid' }

  describe '#full_handle_url' do
    it { expect(described_class.full_handle_url(nil)).to eq described_class::HANDLE_NET_PREFIX }
    it { expect(described_class.full_handle_url('2027/fulcrum.invalidnoid')).to eq described_class::HANDLE_NET_PREFIX + '2027/fulcrum.invalidnoid' }
    it { expect(described_class.full_handle_url('2027/fulcrum.validnoid')).to eq described_class::HANDLE_NET_PREFIX + '2027/fulcrum.validnoid' }
  end

  describe 'Handle Service' do
    let(:handle) { '2027/fulcrum.999999999' }
    let(:url) { double('url') }

    it { expect(described_class.url_value_for_handle(handle)).to be nil }
    it { expect(described_class.create_or_update(handle, url)).to be false }
    it { expect(described_class.delete(handle)).to be false }
    it { expect(described_class.service).to be nil }

    context 'instantiate' do
      let(:handle_service) { instance_double(HandleRest::HandleService, 'handle_service') }
      let(:service) { instance_double(HandleRest::Service, 'service') }
      let(:admin_group) { HandleRest::Identity.from_s("200:0.NA/2027") }
      let(:admin_permission_set) { HandleRest::AdminPermissionSet.from_s("110011110011") }
      let(:admin_group_value) { HandleRest::AdminValue.new(admin_group.index, admin_permission_set, admin_group.handle) }
      let(:admin_group_value_line) { HandleRest::ValueLine.new(100, admin_group_value) }
      let(:url_service) { instance_double(HandleRest::UrlService, 'url_service') }

      before do
        Settings.handle_service.instantiate = true
        allow(Services).to receive(:handle_service).and_return(handle_service)
        allow(HandleRest::Service).to receive(:new).with([admin_group_value_line], handle_service).and_return(service)
        allow(HandleRest::UrlService).to receive(:new).with(1, service).and_return(url_service)
      end

      after { Settings.handle_service.instantiate = false }

      describe '#url_value_for_handle' do
        subject { described_class.url_value_for_handle(handle) }

        before { allow(url_service).to receive(:get).with(handle).and_return(url) }

        it { is_expected.to be url }

        context 'error' do
          let(:logger) { instance_double(Logger, 'logger') }
          let(:message) { "HandleNet.url_value_for_handle(#{handle}) failed with error #{error}" }
          let(:error) { 'error' }

          before do
            allow(Rails).to receive(:logger).and_return(logger)
            allow(logger).to receive(:error).with(message)
            allow(url_service).to receive(:get).with(handle).and_raise(error)
          end

          it do
            is_expected.to be nil
            expect(logger).to have_received(:error).with(message)
          end
        end
      end

      describe '#create_or_update' do
        subject { described_class.create_or_update(handle, url) }

        before { allow(url_service).to receive(:set).with(handle, url).and_return(url) }

        it { is_expected.to be true }

        context 'error' do
          let(:logger) { instance_double(Logger, 'logger') }
          let(:message) { "HandleNet.create_or_update(#{handle}, #{url}) failed with error #{error}" }
          let(:error) { 'error' }

          before do
            allow(Rails).to receive(:logger).and_return(logger)
            allow(logger).to receive(:error).with(message)
            allow(url_service).to receive(:set).with(handle, url).and_raise(error)
          end

          it do
            is_expected.to be false
            expect(logger).to have_received(:error).with(message)
          end
        end
      end

      describe '#delete' do
        subject { described_class.delete(handle) }

        before { allow(service).to receive(:delete).with(HandleRest::Handle.from_s(handle)).and_return([]) }

        it { is_expected.to be true }

        context 'error' do
          let(:logger) { instance_double(Logger, 'logger') }
          let(:message) { "HandleNet.delete(#{handle}) failed with error #{error}" }
          let(:error) { 'error' }

          before do
            allow(Rails).to receive(:logger).and_return(logger)
            allow(logger).to receive(:error).with(message)
            allow(service).to receive(:delete).with(HandleRest::Handle.from_s(handle)).and_raise(error)
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
