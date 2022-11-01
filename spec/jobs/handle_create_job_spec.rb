# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleCreateJob, type: :job do
  include ActiveJob::TestHelper

  let(:handle) { HandleNet::FULCRUM_HANDLE_PREFIX + 'validnoid' }
  let(:url_value) { 'https://fulcrum.org/validnoid' }

  describe 'job queue' do
    subject(:job) { described_class.perform_later(handle, url_value) }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class).with(handle, url_value).on_queue("default")
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
    end
  end

  context 'job' do
    let(:job) { described_class.new }

    describe '#perform' do
      subject { job.perform(handle, url_value) }

      let(:logger) { instance_double(ActiveSupport::Logger, 'logger') }
      let(:record) { instance_double(HandleDeposit, 'record') }
      let(:url) { 'url' }
      let(:rvalue) { double('rvalue') }

      before do
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error).with("HandleDeleteJob #{handle} --> #{url_value} StandardError")
        allow(HandleDeposit).to receive(:find_or_create_by).with(handle: handle).and_return(record)
        allow(record).to receive(:action=).with('create')
        allow(record).to receive(:url_value=).with(url_value)
        allow(record).to receive(:verified=).with(false)
        allow(record).to receive(:save!)
        allow(HandleNet).to receive(:url_value_for_handle).with(handle).and_return(url)
        allow(HandleNet).to receive(:create_or_update).with(handle, url_value).and_return(rvalue)
      end

      context 'handle does not exist' do
        it 'handle service update' do
          is_expected.to be rvalue
          expect(HandleDeposit).to have_received(:find_or_create_by).with(handle: handle)
          expect(record).to have_received(:action=).with('create')
          expect(record).to have_received(:url_value=).with(url_value)
          expect(record).to have_received(:verified=).with(false)
          expect(record).to have_received(:save!)
          expect(HandleNet).to have_received(:url_value_for_handle).with(handle)
          expect(HandleNet).to have_received(:create_or_update).with(handle, url_value)
          expect(logger).not_to have_received(:error).with("HandleDeleteJob #{handle} --> #{url_value} StandardError")
        end
      end

      context 'handle already exists' do
        let(:url) { url_value }

        it 'handle service value' do
          is_expected.to eq(url_value)
          expect(HandleDeposit).to have_received(:find_or_create_by).with(handle: handle)
          expect(record).to have_received(:action=).with('create')
          expect(record).to have_received(:verified=).with(false)
          expect(record).to have_received(:save!)
          expect(HandleNet).to have_received(:url_value_for_handle).with(handle)
          expect(HandleNet).not_to have_received(:create_or_update).with(handle, url_value)
          expect(logger).not_to have_received(:error).with("HandleDeleteJob #{handle} --> #{url_value} StandardError")
        end
      end
    end
  end
end
