# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecacheInCommonMetadataJob, type: :job do
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

    describe 'perform' do
      subject { job.perform }

      before do
        allow(job).to receive(:download_xml).and_return(true)
        allow(job).to receive(:parse_xml).and_return(true)
        allow(job).to receive(:cache_json).and_return(true)
      end

      it do
        is_expected.to be true
        expect(job).to have_received(:download_xml)
        expect(job).to have_received(:parse_xml)
        expect(job).to have_received(:cache_json)
      end

      context 'fail' do
        context 'cache_json' do
          before { allow(job).to receive(:cache_json).and_return(false) }

          it do
            is_expected.to be false
            expect(job).to have_received(:download_xml)
            expect(job).to have_received(:parse_xml)
            expect(job).to have_received(:cache_json)
          end

          context 'parse_xml' do
            before { allow(job).to receive(:parse_xml).and_return(false) }

            it do
              is_expected.to be false
              expect(job).to     have_received(:download_xml)
              expect(job).to     have_received(:parse_xml)
              expect(job).not_to have_received(:cache_json)
            end

            context 'download_xml' do
              before { allow(job).to receive(:download_xml).and_return(false) }

              it do
                is_expected.to be false
                expect(job).to     have_received(:download_xml)
                expect(job).not_to have_received(:parse_xml)
                expect(job).not_to have_received(:cache_json)
              end
            end
          end
        end
      end
    end

    describe '#download_xml' do
      subject { job.download_xml }

      let(:command) { described_class::DOWNLOAD_CMD }
      let(:rvalue) { true }

      before { allow(described_class).to receive(:system_call).with(command).and_return(rvalue) }

      it { is_expected.to be true }

      context 'error' do
        let(:error) { 'error' }

        before do
          allow(Rails.logger).to receive(:error).with(message)
          allow(described_class).to receive(:system_call).with($?).and_return(error)
        end

        context 'false' do
          let(:rvalue) { false }
          let(:message) { "ERROR Command #{command} error code #{error}" }

          it do
            is_expected.to be false
            expect(Rails.logger).to have_received(:error).with(message)
          end
        end

        context 'nil' do
          let(:rvalue) { nil }
          let(:message) { "ERROR Command #{command} not found #{error}" }

          it do
            is_expected.to be false
            expect(Rails.logger).to have_received(:error).with(message)
          end
        end
      end
    end

    describe '#parse_xml' do
      subject { job.parse_xml }

      context 'no file' do
        before { FileUtils.rm(described_class::XML_FILE) if File.exist?(described_class::XML_FILE) }

        it do
          is_expected.to be true
          expect(JSON.load(File.read(described_class::JSON_FILE))).to eq([])
        end
      end

      context 'file' do
        before { FileUtils.cp(Rails.root.join('spec', 'fixtures', 'feed', 'InCommon-metadata.xml'), described_class::XML_FILE) }

        it do
          is_expected.to be true
          expect(FileUtils.compare_file(Rails.root.join('spec', 'fixtures', 'feed', 'InCommon-metadata.json'), described_class::JSON_FILE)).to be true
        end
      end
    end

    describe '#load_json' do
      subject { job.load_json }

      context 'no file' do
        before { FileUtils.rm(described_class::JSON_FILE) if File.exist?(described_class::JSON_FILE) }

        it { is_expected.to eq([]) }
      end

      context 'file' do
        before { FileUtils.cp(Rails.root.join('spec', 'fixtures', 'feed', 'InCommon-metadata.json'), described_class::JSON_FILE) }

        it { is_expected.to eq(JSON.load(File.read(Rails.root.join('spec', 'fixtures', 'feed', 'InCommon-metadata.json')))) }
      end
    end

    describe '#cache_json' do
      subject { job.cache_json }

      before do
        allow(job).to receive(:load_json).and_return([])
        allow(Rails.cache).to receive(:write).with(described_class::RAILS_CACHE_KEY, expires_in: 24.hours).and_yield
      end

      it do
        is_expected.to be true
        expect(job).to have_received(:load_json)
        expect(Rails.cache).to have_received(:write).with(described_class::RAILS_CACHE_KEY, expires_in: 24.hours)
      end
    end
  end
end
