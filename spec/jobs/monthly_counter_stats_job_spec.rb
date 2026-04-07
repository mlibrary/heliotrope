# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonthlyCounterStatsJob, type: :job do
  include ActiveJob::TestHelper

  let(:year) { 2025 }
  let(:month) { 7 }
  let(:target_date) { Date.new(year, month, 1) }
  let(:filename) { "fulcrum_metric_totals-#{year}-#{format('%02d', month)}.csv" }
  let(:config) do
    {
      'Bucket' => 'test-bucket',
      'BucketRegion' => 'us-east-1',
      'AwsAccessKeyId' => 'test-key',
      'AwsSecretAccessKey' => 'test-secret'
    }
  end

  before do
    allow(Time.zone).to receive(:today).and_return(Date.new(2025, 8, 15))
    allow(YAML).to receive(:safe_load).and_return(config)
    allow(Settings).to receive(:scratch_space_path).and_return(Dir.tmpdir)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#perform' do
    context 'when run before the 15th' do
      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2025, 8, 10))
      end

      it 'does not process anything' do
        expect(CounterSummary).not_to receive(:exists_for_period?)
        described_class.new.perform(target_date)
      end

      it 'processes when force is true' do
        # Mock the S3 setup to allow processing
        allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(true)
        allow(File).to receive(:read).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(config.to_yaml)

        s3_resource = instance_double(Aws::S3::Resource)
        s3_bucket = instance_double(Aws::S3::Bucket)
        s3_object = instance_double(Aws::S3::Object)

        allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).and_return(s3_bucket)
        allow(s3_bucket).to receive(:object).and_return(s3_object)
        allow(s3_object).to receive(:get).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'not found'))

        allow(CounterSummaryMailer).to receive(:missing_file).and_return(double(deliver_now: true))
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)

        # The job should attempt to fetch from S3 even before the 15th when force is true
        expect(s3_object).to receive(:get)
        described_class.new.perform(target_date, force: true)
      end
    end

    context 'when statistics already exist for the period' do
      before do
        allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(true)
      end

      it 'does not fetch or process the file' do
        expect(Aws::S3::Resource).not_to receive(:new)
        described_class.new.perform(target_date)
      end

      it 'logs that stats already exist' do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/already exist/)
        described_class.new.perform(target_date)
      end

      context 'with force: true' do
        let(:s3_object) { instance_double(Aws::S3::Object) }
        let(:s3_bucket) { instance_double(Aws::S3::Bucket) }
        let(:s3_resource) { instance_double(Aws::S3::Resource) }
        let(:csv_content) do
          <<~CSV
            Identifier,Total_Item_Requests (for the month),Total_Item_Requests (life to date),Total_Item_Investigations (for the month),Total_Item_Investigations (life to date),Unique_Item_Requests (for the month),Unique_Item_Requests (life to date),Unique_Item_Investigations (for the month),Unique_Item_Investigations (life to date)
            test123,100,1000,150,1500,80,800,120,1200
          CSV
        end

        before do
          # Mock config loading
          allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(true)
          allow(File).to receive(:read).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(config.to_yaml)

          allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(true)
          allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
          allow(s3_resource).to receive(:bucket).and_return(s3_bucket)
          allow(s3_bucket).to receive(:object).and_return(s3_object)
          allow(s3_object).to receive(:get) do |args|
            File.write(args[:response_target], csv_content)
          end

          processor = instance_double(CounterSummaryService::CsvProcessor)
          allow(CounterSummaryService::CsvProcessor).to receive(:new).and_return(processor)
          allow(processor).to receive(:process_file).and_return([
            {
              monograph_noid: 'test123',
              month: month,
              year: year,
              total_item_requests_month: 100,
              total_item_requests_life: 1000,
              total_item_investigations_month: 150,
              total_item_investigations_life: 1500,
              unique_item_requests_month: 80,
              unique_item_requests_life: 800,
              unique_item_investigations_month: 120,
              unique_item_investigations_life: 1200
            }
          ])
          allow(processor).to receive(:errors).and_return([])
          allow(CounterSummary).to receive(:cleanup_old_stats).and_return(0)
          allow(Rails.logger).to receive(:info)
        end

        it 'deletes existing statistics before reprocessing within transaction' do
          existing_relation = double('ActiveRecord::Relation', exists?: true, delete_all: 5)
          allow(CounterSummary).to receive(:for_period).with(year, month).and_return(existing_relation)
          allow(CounterSummary).to receive(:transaction).and_yield
          allow(CounterSummary).to receive(:create!).and_return([double(length: 1)])

          expect(existing_relation).to receive(:delete_all)
          described_class.new.perform(target_date, force: true)
        end

        it 'processes the file' do
          allow(CounterSummary).to receive(:for_period).and_return(double(exists?: false))
          allow(CounterSummary).to receive(:transaction).and_yield
          expect(CounterSummary).to receive(:create!)
          described_class.new.perform(target_date, force: true)
        end
      end
    end

    context 'when file is successfully fetched from S3' do
      let(:s3_object) { instance_double(Aws::S3::Object) }
      let(:s3_bucket) { instance_double(Aws::S3::Bucket) }
      let(:s3_resource) { instance_double(Aws::S3::Resource) }
      let(:s3_key) { "Exports/#{filename}" }
      let(:csv_content) do
        <<~CSV
          Identifier,Total_Item_Requests (for the month),Total_Item_Requests (life to date),Total_Item_Investigations (for the month),Total_Item_Investigations (life to date),Unique_Item_Requests (for the month),Unique_Item_Requests (life to date),Unique_Item_Investigations (for the month),Unique_Item_Investigations (life to date)
          test123,100,1000,150,1500,80,800,120,1200
        CSV
      end

      before do
        # Mock Time.zone.today to be after the 15th so the job will run
        allow(Time.zone).to receive(:today).and_return(Date.new(2025, 7, 16))

        # Mock config loading
        allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(true)
        allow(File).to receive(:read).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(config.to_yaml)

        allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(false)
        allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).with(config['Bucket']).and_return(s3_bucket)
        allow(s3_bucket).to receive(:object).with(s3_key).and_return(s3_object)
        allow(s3_object).to receive(:get) do |args|
          File.write(args[:response_target], csv_content)
        end

        # Mock the processor
        processor = instance_double(CounterSummaryService::CsvProcessor)
        allow(CounterSummaryService::CsvProcessor).to receive(:new).and_return(processor)
        allow(processor).to receive(:process_file).and_return([
          {
            monograph_noid: 'test123',
            month: month,
            year: year,
            total_item_requests_month: 100,
            total_item_requests_life: 1000,
            total_item_investigations_month: 150,
            total_item_investigations_life: 1500,
            unique_item_requests_month: 80,
            unique_item_requests_life: 800,
            unique_item_investigations_month: 120,
            unique_item_investigations_life: 1200
          }
        ])
        allow(processor).to receive(:errors).and_return([])

        allow(CounterSummary).to receive(:transaction).and_yield
        allow(CounterSummary).to receive(:cleanup_old_stats).and_return(0)
      end

      it 'fetches the file from S3' do
        allow(Rails.logger).to receive(:info)
        expect(s3_object).to receive(:get)
        described_class.new.perform(target_date)
      end

      it 'creates statistics records with parsed CSV attributes' do
        allow(Rails.logger).to receive(:info)
        allow(CounterSummary).to receive(:for_period).and_return(double(exists?: false))
        allow(CounterSummary).to receive(:transaction).and_yield
        expect(CounterSummary).to receive(:create!).with([hash_including(
          monograph_noid: 'test123'
        )]).and_return([double])
        described_class.new.perform(target_date)
      end

      it 'wraps saves in a transaction' do
        allow(Rails.logger).to receive(:info)
        allow(CounterSummary).to receive(:for_period).and_return(double(exists?: false))
        allow(CounterSummary).to receive(:create!).and_return([double])
        expect(CounterSummary).to receive(:transaction).and_yield
        described_class.new.perform(target_date)
      end

      it 'cleans up old statistics' do
        allow(Rails.logger).to receive(:info)
        expect(CounterSummary).to receive(:cleanup_old_stats).with(MonthlyCounterStatsJob::CLEANUP_RETENTION_MONTHS)
        described_class.new.perform(target_date)
      end

      it 'logs success' do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/Successfully processed/)
        described_class.new.perform(target_date)
      end
    end

    context 'when file is fetched but processor returns no statistics' do
      let(:s3_object) { instance_double(Aws::S3::Object) }
      let(:s3_bucket) { instance_double(Aws::S3::Bucket) }
      let(:s3_resource) { instance_double(Aws::S3::Resource) }
      let(:s3_key) { "Exports/#{filename}" }

      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2025, 7, 16))
        allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(true)
        allow(File).to receive(:read).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(config.to_yaml)
        allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(false)
        allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).with(config['Bucket']).and_return(s3_bucket)
        allow(s3_bucket).to receive(:object).with(s3_key).and_return(s3_object)
        allow(s3_object).to receive(:get) { |args| File.write(args[:response_target], "") }

        processor = instance_double(CounterSummaryService::CsvProcessor)
        allow(CounterSummaryService::CsvProcessor).to receive(:new).and_return(processor)
        allow(processor).to receive(:process_file).and_return([])
        allow(processor).to receive(:errors).and_return([])
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it 'does not run cleanup' do
        expect(CounterSummary).not_to receive(:cleanup_old_stats)
        described_class.new.perform(target_date)
      end

      it 'does not log success' do
        expect(Rails.logger).not_to receive(:info).with(/Successfully processed/)
        described_class.new.perform(target_date)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(/No statistics to save/)
        described_class.new.perform(target_date)
      end
    end

    context 'when file is not found in S3' do
      let(:s3_object) { instance_double(Aws::S3::Object) }
      let(:s3_bucket) { instance_double(Aws::S3::Bucket) }
      let(:s3_resource) { instance_double(Aws::S3::Resource) }
      let(:s3_key) { "Exports/#{filename}" }

      before do
        # Mock Time.zone.today to be after the 15th so the job will run
        allow(Time.zone).to receive(:today).and_return(Date.new(2025, 7, 16))

        # Mock config loading
        allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(true)
        allow(File).to receive(:read).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(config.to_yaml)

        allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(false)
        allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).with(config['Bucket']).and_return(s3_bucket)
        allow(s3_bucket).to receive(:object).with(s3_key).and_return(s3_object)
        allow(s3_object).to receive(:get).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'not found'))
        allow(Rails.logger).to receive(:info)
      end

      it 'sends an email notification' do
        mailer = instance_double(ActionMailer::MessageDelivery)
        expect(CounterSummaryMailer).to receive(:missing_file).with(year, month).and_return(mailer)
        expect(mailer).to receive(:deliver_now)

        described_class.new.perform(target_date)
      end

      it 'logs a warning' do
        allow(CounterSummaryMailer).to receive(:missing_file).and_return(double(deliver_now: true))
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with(/not found in S3/)
        described_class.new.perform(target_date)
      end
    end

    context 'when config file is missing' do
      before do
        allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(false)
        allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(false)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(/Config file not found/)
        described_class.new.perform(target_date)
      end

      it 'does not attempt to fetch from S3' do
        expect(Aws::S3::Resource).not_to receive(:new)
        described_class.new.perform(target_date)
      end
    end

    context 'when config is missing required keys' do
      let(:invalid_config) { { 'Bucket' => 'test-bucket' } }

      before do
        allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(false)
        allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(true)
        allow(File).to receive(:read).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(invalid_config.to_yaml)
        allow(YAML).to receive(:safe_load).and_return(invalid_config)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs an error about missing keys' do
        expect(Rails.logger).to receive(:error).with(/Missing config keys/)
        described_class.new.perform(target_date)
      end

      it 'does not attempt to fetch from S3' do
        allow(Rails.logger).to receive(:error)
        expect(Aws::S3::Resource).not_to receive(:new)
        described_class.new.perform(target_date)
      end
    end

    context 'when config file is empty or not a Hash' do
      before do
        allow(CounterSummary).to receive(:exists_for_period?).with(year, month).and_return(false)
        allow(File).to receive(:exist?).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return(true)
        allow(File).to receive(:read).with(Rails.root.join('config', 'scholarlyiq.yml')).and_return("")
        allow(YAML).to receive(:safe_load).and_return(nil)
        allow(Rails.logger).to receive(:info)
      end

      it 'logs a clear error about the invalid config' do
        expect(Rails.logger).to receive(:error).with(/Config file is empty or not a valid YAML mapping/)
        described_class.new.perform(target_date)
      end

      it 'does not attempt to fetch from S3' do
        allow(Rails.logger).to receive(:error)
        expect(Aws::S3::Resource).not_to receive(:new)
        described_class.new.perform(target_date)
      end
    end

    context 'with no target_date provided' do
      before do
        allow(CounterSummary).to receive(:exists_for_period?).and_return(false)
        # Mock today to be April 16, 2026 (after the 15th threshold)
        allow(Time.zone).to receive(:today).and_return(Date.new(2026, 4, 16))
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
        allow(CounterSummaryMailer).to receive(:missing_file).and_return(double(deliver_now: true))
      end

      it 'defaults to previous month' do
        # Previous month from April 2026 is March 2026
        expect(CounterSummary).to receive(:exists_for_period?).with(2026, 3)
        described_class.new.perform
      end
    end

    context 'when an error occurs during processing' do
      before do
        allow(CounterSummary).to receive(:exists_for_period?).and_raise(StandardError, "Test error")
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and re-raises' do
        expect {
          described_class.new.perform(target_date)
        }.to raise_error(StandardError, "Test error")

        expect(Rails.logger).to have_received(:error).with(/MonthlyCounterStatsJob error/)
        expect(Rails.logger).to have_received(:error).with(/Test error/)
      end
    end
  end
end
