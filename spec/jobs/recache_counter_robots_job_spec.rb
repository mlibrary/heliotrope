# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecacheCounterRobotsJob, type: :job do
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
        allow(job).to receive(:download_json).and_return(true)
        allow(job).to receive(:cache_pattern_list).and_return(true)
      end

      it do
        is_expected.to be true
        expect(job).to have_received(:download_json)
        expect(job).to have_received(:cache_pattern_list)
      end

      context 'fail' do
        context 'cache_pattern_list' do
          before { allow(job).to receive(:cache_pattern_list).and_return(false) }

          it do
            is_expected.to be false
            expect(job).to have_received(:download_json)
            expect(job).to have_received(:cache_pattern_list)
          end
        end

        context 'download_json' do
          before { allow(job).to receive(:download_json).and_return(false) }

          it do
            is_expected.to be false
            expect(job).to     have_received(:download_json)
            expect(job).not_to have_received(:cache_pattern_list)
          end
        end
      end
    end

    describe '#download_json' do
      subject { job.download_json }

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

    describe '#load_list' do
      subject { job.load_list }

      context 'no file' do
        before { FileUtils.rm(described_class::JSON_FILE) if File.exist?(described_class::JSON_FILE) }

        it { is_expected.to eq([]) }
      end

      context 'file' do
        before { FileUtils.cp(Rails.root.join('spec', 'fixtures', 'feed', 'counter_robots.json'), described_class::JSON_FILE) }
        let(:file) { File.read(Rails.root.join('spec', 'fixtures', 'feed', 'counter_robots.json')) }

        it { is_expected.to eq(JSON.load(file).map { |entry| entry["pattern"] }) }

        context 'standard error' do
          let(:message) { 'ERROR: RecacheCounterRobotsJob#load_list raised StandardError' }

          before do
            allow(JSON).to receive(:load).and_raise(StandardError)
            allow(Rails.logger).to receive(:error).with(message)
          end

          it do
            is_expected.to eq([])
            expect(Rails.logger).to have_received(:error).with(message)
          end
        end
      end
    end

    describe '#cache_pattern_list' do
      subject { job.cache_pattern_list }

      let(:loaded_list) { double('loaded_list') }

      before do
        allow(job).to receive(:load_list).and_return(loaded_list)
        allow(Rails.cache).to receive(:write).with(described_class::RAILS_CACHE_KEY, loaded_list, expires_in: 7.days)
      end

      it do
        is_expected.to be true
        expect(job).to have_received(:load_list)
        expect(Rails.cache).to have_received(:write).with(described_class::RAILS_CACHE_KEY, loaded_list, expires_in: 7.days)
      end
    end
  end
end
