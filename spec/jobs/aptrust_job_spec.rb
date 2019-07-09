# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AptrustJob, type: :job do
  include ActiveJob::TestHelper

  describe 'job queue' do
    subject(:job) { described_class.perform_later }

    let(:monograph_doc) { { 'id' => 'id' } }

    before do
      allow(ActiveFedora::SolrService).to receive(:query).and_return([monograph_doc])
      allow(AptrustDepositJob).to receive(:perform_now).with(monograph_doc['id'])
    end

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class)
        .on_queue("default")
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(AptrustDepositJob).to have_received(:perform_now).with(monograph_doc['id'])
    end
  end

  context 'job' do
    let(:job) { described_class.new }

    describe '#perform' do
      subject { job.perform }

      let(:monograph_doc) { { 'id' => 'id' } }
      let(:up_to_date) { true }

      before do
        allow(job).to receive(:monograph_docs).and_return([monograph_doc])
        allow(job).to receive(:deposit_up_to_date?).with(monograph_doc).and_return(up_to_date)
        allow(AptrustDepositJob).to receive(:perform_now).with(monograph_doc['id'])
      end

      it do
        is_expected.to eq(0)
        expect(AptrustDepositJob).not_to have_received(:perform_now).with(monograph_doc['id'])
      end

      context 'when out-of-date' do
        let(:up_to_date) { false }

        it do
          is_expected.to eq(1)
          expect(AptrustDepositJob).to have_received(:perform_now).with(monograph_doc['id'])
        end
      end
    end

    describe '#monograph_docs' do
      subject { job.monograph_docs }

      it { is_expected.to be_empty }

      context 'when monographs' do
        let(:monograph_docs) { [] }

        before do
          allow(ActiveFedora::SolrService).to receive(:query)
            .with("+has_model_ssim:Monograph AND +visibility_ssi:open AND -suppressed_bsi:true",
                  fl: %w[id date_modified_dtsi has_model_ssim suppressed_bsi visibility_ssi],
                  rows: 100_000)
            .and_return(monograph_docs)
        end

        it { is_expected.to be monograph_docs }
      end
    end

    describe '#file_set_docs' do
      subject { job.file_set_docs(monograph_doc) }

      let(:monograph_doc) { { 'id' => 'id' } }

      it { is_expected.to be_empty }

      context 'when file set docs' do
        let(:file_set_docs) { [] }

        before do
          allow(ActiveFedora::SolrService).to receive(:query)
            .with("+has_model_ssim:FileSet AND +monograph_id_ssim:#{monograph_doc['id']}",
                  fl: %w[id date_modified_dtsi has_model_ssim monograph_id_ssim],
                  rows: 100_000)
            .and_return(file_set_docs)
        end

        it { is_expected.to be file_set_docs }
      end
    end

    describe '#deposit_up_to_date?' do
      subject { job.deposit_up_to_date?(monograph_doc) }

      let(:monograph_doc) { { 'id' => 'id', 'date_modified_dtsi' => monograph_modified_date } }
      let(:monograph_modified_date) { yesterday }
      let(:file_set_doc) { { 'date_modified_dtsi' => file_set_modified_date } }
      let(:file_set_modified_date) { yesterday }
      let(:yesterday) { Time.zone.yesterday.to_s }
      let(:today) { Time.zone.today.to_s }

      it { is_expected.to be false }

      context 'when record' do
        let(:record) { instance_double(AptrustDeposit, 'record', created_at: yesterday) }

        before do
          allow(AptrustDeposit).to receive(:find_by).with(noid: monograph_doc['id']).and_return(record)
          allow(job).to receive(:file_set_docs).with(monograph_doc).and_return([file_set_doc])
        end

        it { is_expected.to be true }

        context 'when monograph modified' do
          let(:monograph_modified_date) { today }

          it { is_expected.to be false }
        end

        context 'when file set modified' do
          let(:file_set_modified_date) { today }

          it { is_expected.to be false }
        end
      end
    end
  end
end
