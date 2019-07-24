# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AptrustVerifyJob, type: :job do
  include ActiveJob::TestHelper

  let(:monograph_id) { 'validnoid' }

  describe 'job queue' do
    subject(:job) { described_class.perform_later(monograph_id) }

    before { allow(Sighrax).to receive(:factory).with(monograph_id).and_call_original }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class)
        .with(monograph_id)
        .on_queue("default")
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(Sighrax).to have_received(:factory).with(monograph_id)
    end
  end

  context 'job' do
    let(:job) { described_class.new }

    describe '#perform' do
      subject { job.perform(monograph_id) }

      it { is_expected.to be false }

      context 'when monograph' do
        let(:monograph) { instance_double(Sighrax::Monograph, 'monograph', is_a?: true, noid: monograph_id) }

        before { allow(Sighrax).to receive(:factory).with(monograph_id).and_return(monograph) }

        it { is_expected.to be false }

        context 'when record' do
          let(:record) { instance_double(AptrustDeposit, 'record', verified: verified) }
          let(:verified) { true }

          before { allow(AptrustDeposit).to receive(:find_by).with(noid: monograph_id).and_return(record) }

          it { is_expected.to be true }

          context 'when not verified' do
            let(:verified) { false }
            let(:boolean) { double('boolean') }

            before { allow(job).to receive(:verify).with(record).and_return(boolean) }

            it { is_expected.to be boolean }
          end
        end
      end
    end

    describe '#verify' do
      subject { job.verify(record) }

      let(:record) { instance_double(AptrustDeposit, 'record', identifier: identifier) }
      let(:identifier) { 'identifier' }
      let(:service) { instance_double(Aptrust::Service, 'service') }
      let(:status) { 'status' }

      before do
        allow(Aptrust::Service).to receive(:new).and_return(service)
        allow(service).to receive(:ingest_status).with(identifier).and_return(status)
        allow(record).to receive(:verified=).with(true)
        allow(record).to receive(:save)
        allow(record).to receive(:delete)
      end

      it do
        is_expected.to be false
        expect(record).not_to have_received(:verified=).with(true)
        expect(record).not_to have_received(:save)
        expect(record).not_to have_received(:delete)
      end

      context 'success' do
        let(:status) { 'SuCcEsS' }

        it do
          is_expected.to be true
          expect(record).to have_received(:verified=).with(true)
          expect(record).to have_received(:save)
          expect(record).not_to have_received(:delete)
        end

        context 'standard error' do
          before { allow(service).to receive(:ingest_status).with(identifier).and_raise(StandardError) }

          it do
            is_expected.to be false
            expect(record).not_to have_received(:verified=).with(true)
            expect(record).not_to have_received(:save)
            expect(record).not_to have_received(:delete)
          end
        end
      end

      context 'failed' do
        let(:status) { 'FaIlEd' }

        it do
          is_expected.to be false
          expect(record).not_to have_received(:verified=).with(true)
          expect(record).not_to have_received(:save)
          expect(record).to have_received(:delete)
        end
      end

      context 'not_found' do
        let(:status) { 'NoT_FoUnD' }

        it do
          is_expected.to be false
          expect(record).not_to have_received(:verified=).with(true)
          expect(record).not_to have_received(:save)
          expect(record).to have_received(:delete)
        end
      end
    end
  end
end
