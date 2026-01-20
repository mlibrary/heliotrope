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
        allow(AptrustVerifyJob).to receive(:perform_now).with(monograph_doc['id'])
        allow(AptrustDepositJob).to receive(:perform_now).with(monograph_doc['id'])
      end

      it do
        is_expected.to eq(0)
        expect(AptrustVerifyJob).to have_received(:perform_now).with(monograph_doc['id'])
        expect(AptrustDepositJob).not_to have_received(:perform_now).with(monograph_doc['id'])
      end

      context 'when out-of-date' do
        let(:up_to_date) { false }

        it do
          is_expected.to eq(1)
          expect(AptrustVerifyJob).not_to have_received(:perform_now).with(monograph_doc['id'])
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
      let(:today) { Time.zone.today.to_s }
      let(:yesterday) { Time.zone.yesterday.to_s }
      let(:day_before_yesterday) { Time.zone.now - (2 * 24 * 60 * 60) }

      it { is_expected.to be false }

      context 'when an APTrust record exists' do
        let(:aptrust_record) { instance_double(AptrustDeposit, 'aptrust_record', created_at: yesterday) }

        before do
          allow(AptrustDeposit).to receive(:find_by).with(noid: monograph_doc['id']).and_return(aptrust_record)
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

        context 'FeaturedRepresentatives exist' do
          context 'APTrust backup has happened since the FR(s) were changed' do
            before do
              FeaturedRepresentative.create(work_id: monograph_doc['id'], file_set_id: '000000000', kind: 'epub', updated_at: day_before_yesterday)
              FeaturedRepresentative.create(work_id: monograph_doc['id'], file_set_id: '111111111', kind: 'pdf_ebook', updated_at: day_before_yesterday)
            end

            it { is_expected.to be true }
          end

          context 'APTrust backup has *not* happened since the FR(s) were changed' do
            before do
              FeaturedRepresentative.create(work_id: monograph_doc['id'], file_set_id: '000000000', kind: 'epub', updated_at: day_before_yesterday)
              FeaturedRepresentative.create(work_id: monograph_doc['id'], file_set_id: '111111111', kind: 'pdf_ebook', updated_at: today)
            end

            it { is_expected.to be false }
          end
        end
      end
    end
  end
end
