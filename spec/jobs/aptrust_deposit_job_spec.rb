# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AptrustDepositJob, type: :job do
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
        let(:record) { instance_double(AptrustDeposit, 'record') }

        before do
          allow(Sighrax).to receive(:factory).with(monograph_id).and_return(monograph)
          allow(AptrustDeposit).to receive(:find_by).with(noid: monograph_id).and_return(record)
          allow(record).to receive(:delete)
          allow(job).to receive(:identifier).with(monograph).and_return('identifier')
          allow(job).to receive(:bag).with(monograph).and_return('bag')
          allow(job).to receive(:tar).with('bag').and_return('tar')
          allow(job).to receive(:deposit).with('tar').and_return(true)
          allow(AptrustDeposit).to receive(:create).with(noid: monograph_id, identifier: 'identifier')
        end

        it do
          is_expected.to be true
          expect(AptrustDeposit).to have_received(:find_by).with(noid: monograph_id)
          expect(record).to have_received(:delete)
          expect(AptrustDeposit).to have_received(:create).with(noid: monograph_id, identifier: 'identifier')
        end

        context 'when deposit fails' do
          before { allow(job).to receive(:deposit).with('tar').and_return(false) }

          it do
            is_expected.to be false
            expect(AptrustDeposit).to have_received(:find_by).with(noid: monograph_id)
            expect(record).to have_received(:delete)
            expect(AptrustDeposit).not_to have_received(:create).with(noid: monograph_id, identifier: 'identifier')
          end
        end

        context 'when standard error' do
          before { allow(job).to receive(:bag).with(monograph).and_raise(StandardError) }

          it do
            is_expected.to be false
            expect(AptrustDeposit).to have_received(:find_by).with(noid: monograph_id)
            expect(record).to have_received(:delete)
            expect(AptrustDeposit).not_to have_received(:create).with(noid: monograph_id, identifier: 'identifier')
          end
        end
      end
    end

    describe '#identifier' do
      subject { job.identifier(monograph) }

      let(:monograph) { instance_double(Sighrax::Monograph, 'monograph', is_a?: true, noid: monograph_id) }
      let(:press) { instance_double(Press, 'press', subdomain: 'subdomain') }
      let(:dirname) { 'fulcrum.org.subdomain-validnoid' }

      before { allow(Sighrax).to receive(:press).with(monograph).and_return(press) }

      it { is_expected.to eq(dirname) }
    end

    describe '#bag' do
      subject { job.bag(monograph) }

      let(:monograph) { instance_double(Sighrax::Monograph, 'monograph', is_a?: true, noid: monograph_id) }
      let(:press) { instance_double(Press, 'press', subdomain: 'subdomain') }
      let(:dirname) { 'fulcrum.org.subdomain-validnoid' }
      let(:bag) { instance_double(BagIt::Bag, 'bag') }
      let(:bag_dir) { File.join('.', dirname) }
      let(:bag_info) { 'bag_info' }
      let(:aptrust_info) { 'aptrust_info' }
      let(:exporter) { instance_double(Export::Exporter, 'exporter') }

      before do
        allow(Sighrax).to receive(:press).with(monograph).and_return(press)
        allow(Dir).to receive(:mkdir).with(dirname)
        allow(BagIt::Bag).to receive(:new).with(bag_dir).and_return(bag)
        allow(job).to receive(:bag_info).with(monograph).and_return(bag_info)
        allow(job).to receive(:aptrust_info).with(monograph).and_return(aptrust_info)
        allow(bag).to receive(:write_bag_info).with(bag_info)
        allow(bag).to receive(:bag_dir).and_return(bag_dir)
        allow(File).to receive(:write).with(File.join(bag.bag_dir, 'aptrust-info.txt'), aptrust_info, mode: "w")
        allow(Export::Exporter).to receive(:new).with(monograph_id).and_return(exporter)
        allow(exporter).to receive(:extract).with("#{bag.bag_dir}/data/", true)
        allow(bag).to receive(:manifest!)
      end

      it { is_expected.to eq(dirname) }
    end

    describe '#bag_info' do
      subject { job.bag_info(monograph) }

      let(:monograph) { instance_double(Sighrax::Monograph, 'monograph', is_a?: true, noid: monograph_id) }
      let(:time) { Time.now }
      let(:timestamp) { Time.parse(time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")).iso8601 }
      let(:bag_info) {
        {
          "Bag-Count" => "1",
          "Bagging-Date" => timestamp,
          "Internal-Sender-Description" => "Bag for a monograph hosted at www.fulcrum.org",
          "Internal-Sender-Identifier" => monograph_id,
          "Source-Organization" => "University of Michigan"
        }
      }

      before { allow(Time).to receive(:now).and_return(time) }

      it { is_expected.to eq(bag_info) }
    end

    describe '#aptrust_info' do
      subject { job.aptrust_info(monograph) }

      let(:monograph) { instance_double(Sighrax::Monograph, 'monograph', is_a?: true, noid: monograph_id) }
      let(:presenter) { instance_double(Hyrax::MonographPresenter, 'presenter', title: 'title', publisher: 'publisher', press: 'press', description: ['description'], creator: ['creator']) }
      let(:aptrust_info) {
        <<~INFO
          Title: #{presenter.title}
          Access: Institution
          Storage-Option: Standard
          Description: This bag contains all of the data and metadata related to a Monograph which has been exported from the Fulcrum publishing platform hosted at https://www.fulcrum.org. The data folder contains a Fulcrum manifest in the form of a CSV file named with the NOID assigned to this Monograph in the Fulcrum repository. This manifest is exported directly from Fulcrum's heliotrope application (https://github.com/mlibrary/heliotrope) and can be used for re-import as well. The first two rows contain column headers and human-readable field descriptions, respectively. {{ The final row contains descriptive metadata for the Monograph; other rows contain metadata for Assets, which may be components of the Monograph or material supplemental to it.}}
          Press-Name: #{presenter.publisher.first}
          Press: #{presenter.press}
          Item Description: #{presenter.description.first}
          Creator/Author: #{presenter.creator.first}
        INFO
      }

      before { allow(Sighrax).to receive(:hyrax_presenter).with(monograph).and_return(presenter) }

      it { is_expected.to eq(aptrust_info) }
    end

    describe '#tar' do
      subject { job.tar(dirname) }

      let(:dirname) { 'dir' }
      let(:filename) { "#{dirname}.tar" }

      before do
        allow(File).to receive(:open).with(filename, 'wb').and_return(filename)
        allow(Minitar).to receive(:pack).with(dirname, filename).and_return(nil)
      end

      it { is_expected.to eq(filename) }
    end

    describe '#deposit' do
      subject { job.deposit(filename) }

      let(:file) { instance_double(File, 'file') }
      let(:yaml) do
        {
          'BucketRegion' => 's3 bucket region',
          'Bucket' => 's3 bucket',
          'AwsAccessKeyId' => 'aws access key id',
          'AwsSecretAccessKey' => 'aws secret access key'
        }
      end
      let(:credentials) { instance_double(Aws::Credentials, 'credentials') }
      let(:config) { double('config') }
      let(:filename) { 'dir.tar' }
      let(:resource) { instance_double(Aws::S3::Resource, 'resource') }
      let(:bucket) { double('bucket') }
      let(:obj) { double('object') }
      let(:boolean) { double('boolean') }

      before do
        allow(Aws::Credentials).to receive(:new).with('aws access key id', 'aws secret access key').and_return(credentials)
        allow(Aws).to receive(:config).and_return(config)
        allow(config).to receive(:update).with(credentials: credentials).and_return(nil)
        allow(File).to receive(:read).with(Rails.root.join('config', 'aptrust.yml')).and_return(file)
        allow(YAML).to receive(:safe_load).with(file).and_return(yaml)
        allow(Aws).to receive(:config).and_return(config)
        allow(Aws::S3::Resource).to receive(:new).with(region: 's3 bucket region').and_return(resource)
        allow(resource).to receive(:bucket).with('s3 bucket').and_return(bucket)
        allow(bucket).to receive(:object).with(File.basename(filename)).and_return(obj)
        allow(obj).to receive(:upload_file).with(filename).and_return(boolean)
      end

      it { is_expected.to be boolean }
    end
  end
end
