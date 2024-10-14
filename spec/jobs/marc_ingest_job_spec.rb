# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarcIngestJob, type: :job do
  let(:files) { ['/local/path/to/file1.mrc', '/local/path/to/file2.mrc'] }
  let(:validator_instance) { instance_double(Marc::Validator) }
  let(:product_dir) { '/product/directory' }

  before do
    allow(MarcLogger).to receive(:info)
    allow(MarcLogger).to receive(:error)
    allow(Marc::Sftp).to receive(:download_marc_ingest_files).and_return(files)
    allow(Marc::Validator).to receive(:new).and_return(validator_instance)
    allow(validator_instance).to receive(:valid?).and_return(true)
    allow(validator_instance).to receive(:group_key).and_return('group_key')
    allow(validator_instance).to receive(:noid).and_return('noid')
    allow(validator_instance).to receive(:file).and_return('/local/path/to/file.mrc')
    allow(Marc::DirectoryMapper).to receive(:group_key_cataloging).and_return('group_key' => product_dir)
    allow(Marc::Sftp).to receive(:move_marc_ingest_file_to_product_dir)
    allow(Marc::Sftp).to receive(:move_marc_ingest_file_to_failures)
    allow(FileUtils).to receive(:rm)
    allow(MarcIngestMailer).to receive(:send_mail)
  end

  describe '#perform' do
    it 'logs the beginning of the job' do
      MarcIngestJob.perform_now
      expect(MarcLogger).to have_received(:info).with("Beginning MarcIngestJob...")
    end

    context 'when no files are found' do
      before do
        allow(Marc::Sftp).to receive(:download_marc_ingest_files).and_return([])
      end

      it 'logs that no new MARC files are found and returns' do
        MarcIngestJob.perform_now
        expect(MarcLogger).to have_received(:info).with("No new marc files found in /marc_ingest")
      end
    end

    context 'when files are found' do
      it 'logs the number of files found' do
        MarcIngestJob.perform_now
        expect(MarcLogger).to have_received(:info).with("#{files.count} files found in /marc_ingest")
      end

      context 'when the validator is valid' do
        it 'moves the remote file to the remote product directory and removes the local copy' do
          MarcIngestJob.perform_now
          expect(Marc::Sftp).to have_received(:move_marc_ingest_file_to_product_dir).with('/local/path/to/file.mrc', product_dir).twice
          expect(FileUtils).to have_received(:rm).with(files.first)
          expect(FileUtils).to have_received(:rm).with(files.last)
        end

        it 'sends a success report' do
          report = files.map { "SUCCESS\tgroup_key noid file.mrc moved to #{product_dir}" }
          MarcIngestJob.perform_now
          expect(MarcIngestMailer).to have_received(:send_mail).with(report)
        end
      end

      context 'when the validator is invalid' do
        before do
          allow(validator_instance).to receive(:valid?).and_return(false)
          allow(validator_instance).to receive(:error).and_return("Validation error")
        end

        it 'moves the file to marc_ingest/failres, removes the local copy and logs validation error' do
          MarcIngestJob.perform_now
          expect(Marc::Sftp).to have_received(:move_marc_ingest_file_to_failures).with('/local/path/to/file.mrc').twice
          expect(FileUtils).to have_received(:rm).with(files.first)
          expect(FileUtils).to have_received(:rm).with(files.last)
        end

        it 'sends a failure report' do
          report = ["Validation error", "Validation error"]
          MarcIngestJob.perform_now
          expect(MarcIngestMailer).to have_received(:send_mail).with(report)
        end
      end

      context 'when the group_key does not have a directory mapping' do
        before do
          allow(Marc::DirectoryMapper).to receive(:group_key_cataloging).and_return({})
        end

        it 'logs an error and skips the file' do
          MarcIngestJob.perform_now
          expect(MarcLogger).to have_received(:error).with("ERROR\tMarc::DirectoryMapper is missing a group_key/cataloging path for 'group_key' with file '/local/path/to/file1.mrc'!")
          expect(MarcLogger).to have_received(:error).with("ERROR\tMarc::DirectoryMapper is missing a group_key/cataloging path for 'group_key' with file '/local/path/to/file2.mrc'!")
          expect(FileUtils).to have_received(:rm).with(files.first)
          expect(FileUtils).to have_received(:rm).with(files.last)
        end

        it 'sends a report with the error message' do
          report = [
            "ERROR\tMarc::DirectoryMapper is missing a group_key/cataloging path for 'group_key' with file '/local/path/to/file1.mrc'!",
            "ERROR\tMarc::DirectoryMapper is missing a group_key/cataloging path for 'group_key' with file '/local/path/to/file2.mrc'!",
          ]
          MarcIngestJob.perform_now
          expect(MarcIngestMailer).to have_received(:send_mail).with(report)
        end
      end
    end
  end
end
