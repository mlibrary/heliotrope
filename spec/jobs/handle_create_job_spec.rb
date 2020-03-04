# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleCreateJob, type: :job do
  include ActiveJob::TestHelper

  let(:model_id) { 'validnoid' }

  describe 'job queue' do
    subject(:job) { described_class.perform_later(model_id) }

    before { allow(Sighrax).to receive(:from_noid).with(model_id).and_call_original }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class).with(model_id).on_queue("default")
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(Sighrax).to have_received(:from_noid).with(model_id)
    end
  end

  context 'job' do
    let(:job) { described_class.new }

    describe '#perform' do
      subject { job.perform(model_id) }

      let(:logger) { instance_double(ActiveSupport::Logger, 'logger') }

      before do
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:warn).with("HandleCreateJob #{model_id} is NOT kind of Sighrax::Model")
        allow(logger).to receive(:error).with("HandleCreateJob #{model_id} StandardError")
      end

      it 'logs warning' do
        is_expected.to be false
        expect(logger).to have_received(:warn).with("HandleCreateJob #{model_id} is NOT kind of Sighrax::Model")
        expect(logger).not_to have_received(:error).with("HandleCreateJob #{model_id} StandardError")
      end

      context 'when model' do
        let(:model) { instance_double(Sighrax::Model, 'model', kind_of?: true, noid: model_id, resource_type: 'Model') }
        let(:record) { instance_double(HandleDeposit, 'record') }
        let(:boolean) { double('boolean') }

        before do
          allow(Sighrax).to receive(:from_noid).with(model_id).and_return(model)
          allow(HandleDeposit).to receive(:find_or_create_by).with(noid: model_id).and_return(record)
          allow(record).to receive(:action=).with('create')
          allow(record).to receive(:verified=).with(false)
          allow(record).to receive(:save!)
          allow(job).to receive(:create_handle).with(model).and_return(boolean)
        end

        it 'returns create handle' do
          is_expected.to be boolean
          expect(HandleDeposit).to have_received(:find_or_create_by).with(noid: model_id)
          expect(record).to have_received(:action=).with('create')
          expect(record).to have_received(:verified=).with(false)
          expect(record).to have_received(:save!)
          expect(logger).not_to have_received(:warn).with("HandleCreateJob #{model_id} is NOT kind of Sighrax::Model")
          expect(logger).not_to have_received(:error).with("HandleCreateJob #{model_id} StandardError")
        end

        context 'when standard error' do
          before { allow(job).to receive(:create_handle).with(model).and_raise(StandardError) }

          it 'logs error' do
            is_expected.to be false
            expect(HandleDeposit).to have_received(:find_or_create_by).with(noid: model_id)
            expect(record).to have_received(:action=).with('create')
            expect(record).to have_received(:verified=).with(false)
            expect(record).to have_received(:save!)
            expect(logger).not_to have_received(:warn).with("HandleCreateJob #{model_id} is NOT kind of Sighrax::Model")
            expect(logger).to have_received(:error).with("HandleCreateJob #{model_id} StandardError")
          end
        end
      end
    end

    describe '#create_handle' do
      subject { job.create_handle(model) }

      let(:model) { instance_double(Sighrax::Model, 'model', noid: model_id) }
      let(:model_url) { 'model_url' }
      let(:url) { 'url' }
      let(:rvalue) { double('rvalue') }

      before do
        allow(Sighrax).to receive(:url).with(model).and_return(model_url)
        allow(HandleNet).to receive(:value).with(model.noid).and_return(url)
        allow(HandleNet).to receive(:create_or_update).with(model.noid, model_url).and_return(rvalue)
      end

      it 'handle service update' do
        is_expected.to be rvalue
        expect(HandleNet).to have_received(:value).with(model.noid)
        expect(HandleNet).to have_received(:create_or_update).with(model.noid, model_url)
      end

      context 'handle exist' do
        let(:url) { model_url }

        it 'handle service value' do
          is_expected.to eq(model_url)
          expect(HandleNet).to have_received(:value).with(model.noid)
          expect(HandleNet).not_to have_received(:create_or_update).with(model.noid, model_url)
        end
      end
    end
  end
end
