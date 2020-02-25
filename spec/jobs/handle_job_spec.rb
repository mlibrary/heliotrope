# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleJob, type: :job do
  include ActiveJob::TestHelper

  let(:model_doc) { { 'id' => 'model_id' } }

  before do
    allow(HandleDeleteJob).to receive(:perform_now).with(model_doc['id'])
    allow(HandleCreateJob).to receive(:perform_now).with(model_doc['id'])
    allow(HandleVerifyJob).to receive(:perform_now).with(model_doc['id'])
  end

  describe '#thirty_days_ago' do
    it { expect(described_class.thirty_days_ago < 29.days.ago).to be true }
    it { expect(described_class.thirty_days_ago > 31.days.ago).to be true }
  end

  describe 'job queue' do
    subject(:job) { described_class.perform_later }

    before { allow(ActiveFedora::SolrService).to receive(:query).and_return([model_doc]) }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class).on_queue("default")
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
      expect(HandleCreateJob).to have_received(:perform_now).with(model_doc['id'])
      expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
      expect(HandleDeposit.all.count).to eq(1)
      HandleDeposit.all.each do |record|
        expect(record.noid).to eq(model_doc['id'])
        expect(record.action).to eq('create')
        expect(record.verified).to be false
      end
    end
  end

  context 'job' do
    let(:job) { described_class.new }

    describe '#perform' do
      subject { job.perform }

      let(:model_docs) { [] }

      before { allow(job).to receive(:model_docs).and_return(model_docs) }

      it 'does nothing' do
        is_expected.to be true
        expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
        expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
        expect(HandleVerifyJob).not_to have_received(:perform_now).with(model_doc['id'])
        expect(HandleDeposit.all.count).to eq(0)
      end

      context 'when model doc' do
        let(:model_docs) { [model_doc] }

        it 'creates and verifies creation of handle' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleCreateJob).to have_received(:perform_now).with(model_doc['id'])
          expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.noid).to eq(model_doc['id'])
            expect(record.action).to eq('create')
            expect(record.verified).to be false
          end
        end
      end

      context 'when delete not verified' do
        before { HandleDeposit.create(noid: model_doc['id'], action: 'delete') }

        it 'deletes' do
          is_expected.to be true
          expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleDeleteJob).to have_received(:perform_now).with(model_doc['id'])
          expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.noid).to eq(model_doc['id'])
            expect(record.action).to eq('delete')
            expect(record.verified).to be false
          end
        end

        context 'when model doc' do
          let(:model_docs) { [model_doc] }

          it 'overrides delete with create' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.noid).to eq(model_doc['id'])
              expect(record.action).to eq('create')
              expect(record.verified).to be false
            end
          end
        end
      end

      context 'when delete verified' do
        before { HandleDeposit.create(noid: model_doc['id'], action: 'delete', verified: true) }

        it 'does nothing' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleVerifyJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.noid).to eq(model_doc['id'])
            expect(record.action).to eq('delete')
            expect(record.verified).to be true
          end
        end

        context 'when model doc' do
          let(:model_docs) { [model_doc] }

          it 'overrides delete with create' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.noid).to eq(model_doc['id'])
              expect(record.action).to eq('create')
              expect(record.verified).to be false
            end
          end
        end
      end

      context 'when create not verified' do
        before { HandleDeposit.create(noid: model_doc['id'], action: 'create') }

        it 'creates' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleCreateJob).to have_received(:perform_now).with(model_doc['id'])
          expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.noid).to eq(model_doc['id'])
            expect(record.action).to eq('create')
            expect(record.verified).to be false
          end
        end

        context 'when model doc' do
          let(:model_docs) { [model_doc] }

          it 'creates' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.noid).to eq(model_doc['id'])
              expect(record.action).to eq('create')
              expect(record.verified).to be false
            end
          end
        end
      end

      context 'when create verified' do
        before { HandleDeposit.create(noid: model_doc['id'], action: 'create', verified: true) }

        it 'does nothing' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleVerifyJob).not_to have_received(:perform_now).with(model_doc['id'])
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.noid).to eq(model_doc['id'])
            expect(record.action).to eq('create')
            expect(record.verified).to be true
          end
        end

        context 'when model doc' do
          let(:model_docs) { [model_doc] }

          it 'does nothing' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.noid).to eq(model_doc['id'])
              expect(record.action).to eq('create')
              expect(record.verified).to be true
            end
          end
        end
      end

      context 'when record older than 30 days' do
        before { allow(described_class).to receive(:thirty_days_ago).and_return(31.days.from_now) }

        context 'when delete not verified' do
          before { HandleDeposit.create(noid: model_doc['id'], action: 'delete') }

          it 'deletes handle' do
            is_expected.to be true
            expect(HandleDeleteJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.noid).to eq(model_doc['id'])
              expect(record.action).to eq('delete')
              expect(record.verified).to be false
            end
          end
        end

        context 'when delete verified' do
          before { HandleDeposit.create(noid: model_doc['id'], action: 'delete', verified: true) }

          it 'deletes record' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(0)
          end
        end

        context 'when create not verified' do
          before { HandleDeposit.create(noid: model_doc['id'], action: 'create') }

          it 'overrides create and deletes handle' do
            is_expected.to be true
            expect(HandleDeleteJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.noid).to eq(model_doc['id'])
              expect(record.action).to eq('delete')
              expect(record.verified).to be false
            end
          end
        end

        context 'when create verified' do
          before { HandleDeposit.create(noid: model_doc['id'], action: 'create', verified: true) }

          it 'overrides create and deletes handle' do
            is_expected.to be true
            expect(HandleDeleteJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleCreateJob).not_to have_received(:perform_now).with(model_doc['id'])
            expect(HandleVerifyJob).to have_received(:perform_now).with(model_doc['id'])
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.noid).to eq(model_doc['id'])
              expect(record.action).to eq('delete')
              expect(record.verified).to be false
            end
          end
        end
      end
    end

    describe '#model_docs' do
      subject { job.model_docs }

      it 'is empty' do
        is_expected.to be_empty
      end

      context 'when models' do
        let(:model_docs) { [] }

        before do
          allow(ActiveFedora::SolrService).to receive(:query)
            .with("+has_model_ssim:[* TO *]",
              fl: %w[id has_model_ssim],
              rows: 100_000)
            .and_return(model_docs)
        end

        it 'returns model docs' do
          is_expected.to be model_docs
        end
      end
    end
  end
end
