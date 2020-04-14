# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MigrateMetadataJob, type: :job do
  include ActiveJob::TestHelper

  describe 'job queue' do
    subject(:job) { described_class.perform_later }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class).on_queue("default")
    end
  end

  context 'job' do
    let(:job) { described_class.new }
    let(:kind) { 'kind' }
    let(:target) { nil }

    describe '#perform' do
      subject { job.perform(kind, target) }

      it { is_expected.to be true }

      context 'transcript' do
        let(:kind) { 'transcript' }
        let(:file_set_1) { create(:public_file_set) }
        let(:file_set_2) { create(:public_file_set) }

        before do
          allow(job).to receive(:migrate_transcript_to_captions).with(file_set_1.id).and_return(true)
          allow(job).to receive(:migrate_transcript_to_captions).with(file_set_2.id).and_return(true)
        end

        it 'all file sets' do
          is_expected.to be true
          expect(job).to have_received(:migrate_transcript_to_captions).with(file_set_1.id)
          expect(job).to have_received(:migrate_transcript_to_captions).with(file_set_2.id)
        end

        context 'file set' do
          let(:target) { file_set_2.id }

          it 'file set 2' do
            is_expected.to be true
            expect(job).not_to have_received(:migrate_transcript_to_captions).with(file_set_1.id)
            expect(job).to     have_received(:migrate_transcript_to_captions).with(file_set_2.id)
          end
        end
      end
    end

    describe '#migrate_transcript_captions' do
      subject { job.migrate_transcript_to_captions(noid) }

      context 'not found' do
        let(:noid) { 'validnoid' }
        let(:message) { "ERROR: MigrateMetadataJob#migrate_transcript_to_captions(#{noid}) raised Couldn't find FileSet with 'id'=#{noid}" }

        before { allow(Rails.logger).to receive(:error).with(message) }

        it do
          is_expected.to be false
          expect(Rails.logger).to have_received(:error).with(message)
        end
      end

      context 'file set' do
        let(:noid) { file_set.id }
        let(:file_set) { create(:public_file_set) }

        it { is_expected.to be false }

        context 'transcript' do
          let(:file_set) { create(:public_file_set, transcript: 'transcript') }

          it 'migrates' do
            is_expected.to be true
            file_set.reload
            expect(file_set.closed_captions).to eq(['transcript'])
          end

          context 'closed_captions' do
            let(:file_set) { create(:public_file_set, transcript: 'transcript', closed_captions: ['closed_captions']) }

            it do
              is_expected.to be false
              file_set.reload
              expect(file_set.closed_captions).to eq(['closed_captions'])
            end
          end
        end
      end
    end
  end
end
