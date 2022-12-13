# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleJob, type: :job do
  include ActiveJob::TestHelper

  let(:handle) { '2027/fulcrum.model_id' }
  let(:url_value) { 'http://test.host/concern/monographs/model_id' }
  let(:model_doc) { { 'id' => 'model_id', 'has_model_ssim' => ['Monograph'] } } # NB: `has_model_ssim` cardinality!

  before do
    allow(HandleDeleteJob).to receive(:perform_now).with(handle)
    allow(HandleCreateJob).to receive(:perform_now).with(handle, url_value)
    allow(HandleVerifyJob).to receive(:perform_now).with(handle)
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

    context "A Monograph's Solr doc" do
      it 'executes perform correctly' do
        perform_enqueued_jobs { job }
        expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
        expect(HandleCreateJob).to have_received(:perform_now).with(handle, url_value)
        expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
        expect(HandleDeposit.all.count).to eq(1)
        HandleDeposit.all.each do |record|
          expect(record.handle).to eq(handle)
          expect(record.action).to eq('create')
          expect(record.verified).to be false
        end
      end
    end

    context "A FileSet's Solr doc" do
      let(:url_value) { 'http://test.host/concern/file_sets/model_id' }
      let(:model_doc) { { 'id' => 'model_id', 'has_model_ssim' => ['FileSet'] } } # NB: `has_model_ssim` cardinality!

      it 'executes perform correctly' do
        perform_enqueued_jobs { job }
        expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
        expect(HandleCreateJob).to have_received(:perform_now).with(handle, url_value)
        expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
        expect(HandleDeposit.all.count).to eq(1)
        HandleDeposit.all.each do |record|
          expect(record.handle).to eq(handle)
          expect(record.action).to eq('create')
          expect(record.verified).to be false
        end
      end
    end
  end

  context 'job' do
    let(:job) { described_class.new }

    describe '#perform' do
      subject { job.perform }

      let(:required_handles) { {} }

      before { allow(job).to receive(:required_handles).and_return(required_handles) }

      it 'does nothing' do
        is_expected.to be true
        expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
        expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
        expect(HandleVerifyJob).not_to have_received(:perform_now).with(handle)
        expect(HandleDeposit.all.count).to eq(0)
      end

      context 'when model doc' do
        let(:required_handles) { { handle => 'http://test.host/concern/monographs/model_id' } }

        it 'creates and verifies creation of handle' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
          expect(HandleCreateJob).to have_received(:perform_now).with(handle, url_value)
          expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.handle).to eq(handle)
            expect(record.action).to eq('create')
            expect(record.verified).to be false
          end
        end
      end

      context 'when delete not verified' do
        before { HandleDeposit.create(handle: handle, action: 'delete') }

        it 'deletes' do
          is_expected.to be true
          expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
          expect(HandleDeleteJob).to have_received(:perform_now).with(handle)
          expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.handle).to eq(handle)
            expect(record.action).to eq('delete')
            expect(record.verified).to be false
          end
        end

        context 'when model doc' do
          let(:required_handles) { { handle => 'http://test.host/concern/monographs/model_id' } }

          it 'overrides delete with create' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.handle).to eq(handle)
              expect(record.action).to eq('create')
              expect(record.verified).to be false
            end
          end
        end
      end

      context 'when delete verified' do
        before { HandleDeposit.create(handle: handle, action: 'delete', verified: true) }

        it 'does nothing' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
          expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
          expect(HandleVerifyJob).not_to have_received(:perform_now).with(handle)
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.handle).to eq(handle)
            expect(record.action).to eq('delete')
            expect(record.verified).to be true
          end
        end

        context 'when model doc' do
          let(:required_handles) { { handle => 'http://test.host/concern/monographs/model_id' } }

          it 'overrides delete with create' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.handle).to eq(handle)
              expect(record.action).to eq('create')
              expect(record.verified).to be false
            end
          end
        end
      end

      context 'when create not verified' do
        before { HandleDeposit.create(handle: handle, url_value: 'http://test.host/concern/monographs/model_id', action: 'create') }

        it 'creates' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
          expect(HandleCreateJob).to have_received(:perform_now).with(handle, url_value)
          expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.handle).to eq(handle)
            expect(record.action).to eq('create')
            expect(record.verified).to be false
          end
        end

        context 'when model doc' do
          let(:model_docs) { [model_doc] }

          it 'creates' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.handle).to eq(handle)
              expect(record.action).to eq('create')
              expect(record.verified).to be false
            end
          end
        end
      end

      context 'when create verified' do
        before { HandleDeposit.create(handle: handle, action: 'create', verified: true) }

        it 'does nothing' do
          is_expected.to be true
          expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
          expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
          expect(HandleVerifyJob).not_to have_received(:perform_now).with(handle)
          expect(HandleDeposit.all.count).to eq(1)
          HandleDeposit.all.each do |record|
            expect(record.handle).to eq(handle)
            expect(record.action).to eq('create')
            expect(record.verified).to be true
          end
        end

        context 'when model doc' do
          let(:model_docs) { [model_doc] }

          it 'does nothing' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).not_to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.handle).to eq(handle)
              expect(record.action).to eq('create')
              expect(record.verified).to be true
            end
          end
        end
      end

      context 'when record older than 30 days' do
        before { allow(described_class).to receive(:thirty_days_ago).and_return(31.days.from_now) }

        context 'when delete not verified' do
          before { HandleDeposit.create(handle: handle, action: 'delete') }

          it 'deletes handle' do
            is_expected.to be true
            expect(HandleDeleteJob).to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.handle).to eq(handle)
              expect(record.action).to eq('delete')
              expect(record.verified).to be false
            end
          end
        end

        context 'when delete verified' do
          before { HandleDeposit.create(handle: handle, action: 'delete', verified: true) }

          it 'deletes record' do
            is_expected.to be true
            expect(HandleDeleteJob).not_to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).not_to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(0)
          end
        end

        context 'when create not verified' do
          before { HandleDeposit.create(handle: handle, action: 'create') }

          it 'overrides create and deletes handle' do
            is_expected.to be true
            expect(HandleDeleteJob).to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.handle).to eq(handle)
              expect(record.action).to eq('delete')
              expect(record.verified).to be false
            end
          end
        end

        context 'when create verified' do
          before { HandleDeposit.create(handle: handle, action: 'create', verified: true) }

          it 'overrides create and deletes handle' do
            is_expected.to be true
            expect(HandleDeleteJob).to have_received(:perform_now).with(handle)
            expect(HandleCreateJob).not_to have_received(:perform_now).with(handle, url_value)
            expect(HandleVerifyJob).to have_received(:perform_now).with(handle)
            expect(HandleDeposit.all.count).to eq(1)
            HandleDeposit.all.each do |record|
              expect(record.handle).to eq(handle)
              expect(record.action).to eq('delete')
              expect(record.verified).to be false
            end
          end
        end
      end
    end

    describe '#required_handles' do
      subject { job.required_handles }

      it 'is empty' do
        is_expected.to be_empty
      end

      context 'when models' do
        before do
          allow(ActiveFedora::SolrService).to receive(:query)
            .with("+(has_model_ssim:Monograph OR has_model_ssim:FileSet)",
              fl: %w[id has_model_ssim],
              rows: 100_000)
            .and_return([model_doc])
        end

        it 'returns handles' do
          is_expected.to eq({ "2027/fulcrum.model_id" => "http://test.host/concern/monographs/model_id" })
        end
      end
    end

    context '#required_heb_monograph_handles' do
      subject { job.required_heb_monograph_handles }

      it 'is empty' do
        is_expected.to be_empty
      end

      context 'with HEB Monographs' do
        before do
          ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '000000000',
                                          press_sim: 'heb', identifier_tesim: ['heb_id: heb01234.0001.001, heb12345.0001.001'] })
          ActiveFedora::SolrService.commit
        end

        it 'returns handles' do
          is_expected.to eq({ "2027/heb01234.0001.001" => "http://test.host/concern/monographs/000000000",
                              "2027/heb12345.0001.001" => "http://test.host/concern/monographs/000000000",
                              "2027/heb01234" => "http://test.host/concern/monographs/000000000",
                              "2027/heb12345" => "http://test.host/concern/monographs/000000000" })
        end

        context 'with multi-volume HEB Monographs' do
          before do
            ActiveFedora::SolrService.add({ has_model_ssim: ['Monograph'], id: '111111111',
                                            press_sim: 'heb', identifier_tesim: ['heb_id: heb01234.0002.001'] })
            ActiveFedora::SolrService.commit
          end

          it 'returns handles with multi-volume title handle pointing to a Blacklight wildcard search' do
            is_expected.to eq({ "2027/heb01234.0001.001" => "http://test.host/concern/monographs/000000000",
                                "2027/heb12345.0001.001" => "http://test.host/concern/monographs/000000000",
                                "2027/heb01234" => "http://test.host/heb?q=heb01234*",
                                "2027/heb12345" => "http://test.host/concern/monographs/000000000",
                                "2027/heb01234.0002.001" => "http://test.host/concern/monographs/111111111" })
          end
        end
      end
    end
  end
end
