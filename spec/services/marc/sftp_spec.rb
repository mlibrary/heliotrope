# frozen_string_literal: true

require 'rails_helper'
require 'net/sftp'

# Lots of mocks here unsurprisingly. It's pretty gross.
RSpec.describe Marc::Sftp do
  describe "#conn" do
    context "with a valid config" do
      let(:valid_yaml) do
        {
          'fulcrum_sftp_credentials' => {
            'sftp' => 'hostname',
            'user' => 'username',
            'password' => 'password',
            'root' => '/'
          }
        }
      end
      let(:sftp_session) { instance_double(Net::SFTP::Session) }
      let(:config) { double("config") }

      before do
        allow(Rails.root).to receive(:join).with('config', 'fulcrum_sftp.yml').and_return(config)
        allow(File).to receive(:exist?).with(config).and_return(true)
        allow(File).to receive(:read).with(config).and_return(true)
        allow(YAML).to receive(:safe_load).and_return valid_yaml
        allow(Net::SFTP).to receive(:start).with("hostname", "username", password: "password").and_return(sftp_session)
      end

      it "starts the Net::SFTP session" do
        sftp = described_class.new
        expect(sftp.conn).to be(sftp_session)
      end
    end

    context "when config is not present" do
      before do
        allow_any_instance_of(described_class).to receive(:yaml_config).and_return(nil)
        allow(MarcLogger).to receive(:error)
      end

      it 'logs an error and returns nil' do
        sftp = described_class.new
        expect(sftp.conn).to be_nil
        expect(MarcLogger).to have_received(:error).with("No ftp.fulcrum.org credentials present!").twice
      end
    end
  end

  describe '#download_marc_ingest_files' do
    let(:valid_yaml) do
      {
        'fulcrum_sftp_credentials' => {
          'sftp' => 'hostname',
          'user' => 'username',
          'password' => 'password',
          'root' => '/'
        }
      }
    end
    let(:config) { double("config") }
    let(:local_marc_processing_dir) { '/tmp/marc_processing' }
    let(:file_entry) { double("Net::SFTP::Entry", file?: true, name: "test_file.mrc") }
    let(:sftp_dir) { instance_double(Net::SFTP::Operations::Dir) }
    let(:sftp_session) { instance_double(Net::SFTP::Session) }

    before do
      allow(Rails.root).to receive(:join).with('config', 'fulcrum_sftp.yml').and_return(config)
      allow(File).to receive(:exist?).with(config).and_return(true)
      allow(File).to receive(:read).with(config).and_return(true)
      allow(YAML).to receive(:safe_load).and_return(valid_yaml)
      allow(Net::SFTP).to receive(:start).with("hostname", "username", password: "password").and_return(sftp_session)

      allow_any_instance_of(Marc::Sftp).to receive(:local_marc_processing_dir).and_return(local_marc_processing_dir)
      allow(FileUtils).to receive(:mkdir_p)
      allow(sftp_session).to receive(:dir).and_return(sftp_dir)
      allow(sftp_dir).to receive(:foreach).with("/home/fulcrum_ftp/marc_ingest").and_yield(file_entry)
      allow(sftp_session).to receive(:download!)
    end

    it 'downloads files from the SFTP server and saves them locally' do
      sftp = described_class.new
      files = sftp.download_marc_ingest_files

      expect(sftp_session).to have_received(:download!).with("/home/fulcrum_ftp/marc_ingest/test_file.mrc", "#{local_marc_processing_dir}/test_file.mrc")
      expect(files).to include("#{local_marc_processing_dir}/test_file.mrc")
    end
  end

  describe "#upload_local_marc_file_to_remote_product_dir" do
    let(:valid_yaml) do
      {
        'fulcrum_sftp_credentials' => {
          'sftp' => 'hostname',
          'user' => 'username',
          'password' => 'password',
          'root' => '/'
        }
      }
    end
    let(:config) { double("config") }
    let(:sftp_session) { instance_double(Net::SFTP::Session) }
    let(:local_file) { File.join(Settings.scratch_space_path, "marc_processing", "test_dir", "test_file.xml") }
    let(:product_dir) { "/home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC" }

    before do
      allow(Rails.root).to receive(:join).with('config', 'fulcrum_sftp.yml').and_return(config)
      allow(File).to receive(:exist?).with(config).and_return(true)
      allow(File).to receive(:read).with(config).and_return(true)
      allow(YAML).to receive(:safe_load).and_return(valid_yaml)
      allow(Net::SFTP).to receive(:start).with("hostname", "username", password: "password").and_return(sftp_session)
      allow(sftp_session).to receive(:upload!)
    end

    it "uploads the local file to the remote product directory" do
      sftp = described_class.new
      sftp.upload_local_marc_file_to_remote_product_dir(local_file, product_dir)
      expect(sftp_session).to have_received(:upload!).with(local_file, product_dir)
    end
  end

  describe '#remove_marc_ingest_file' do
    let(:valid_yaml) do
      {
        'fulcrum_sftp_credentials' => {
          'sftp' => 'hostname',
          'user' => 'username',
          'password' => 'password',
          'root' => '/'
        }
      }
    end
    let(:config) { double("config") }
    let(:sftp_session) { instance_double(Net::SFTP::Session) }

    before do
      allow(Rails.root).to receive(:join).with('config', 'fulcrum_sftp.yml').and_return(config)
      allow(File).to receive(:exist?).with(config).and_return(true)
      allow(File).to receive(:read).with(config).and_return(true)
      allow(YAML).to receive(:safe_load).and_return(valid_yaml)
      allow(Net::SFTP).to receive(:start).with("hostname", "username", password: "password").and_return(sftp_session)
      allow(sftp_session).to receive(:remove!)
    end

    it 'removes a file from the SFTP server' do
      sftp = described_class.new
      sftp.remove_marc_ingest_file('test_file.mrc')

      expect(sftp_session).to have_received(:remove!).with("/home/fulcrum_ftp/marc_ingest/test_file.mrc")
    end
  end

  describe "#upload_local_marc_file_to_remote_failures" do
    let(:valid_yaml) do
      {
        'fulcrum_sftp_credentials' => {
          'sftp' => 'hostname',
          'user' => 'username',
          'password' => 'password',
          'root' => '/'
        }
      }
    end
    let(:config) { double("config") }
    let(:sftp_session) { instance_double(Net::SFTP::Session) }
    let!(:local_file) { File.join(Settings.scratch_space_path, "marc_processing", "test", "test_00001.xml") }
    let!(:remote_failure_file) { "/home/fulcrum_ftp/marc_ingest/failures/test_00001.xml" }

    before do
      allow(Rails.root).to receive(:join).with('config', 'fulcrum_sftp.yml').and_return(config)
      allow(File).to receive(:exist?).with(config).and_return(true)
      allow(File).to receive(:read).with(config).and_return(true)
      allow(YAML).to receive(:safe_load).and_return(valid_yaml)
      allow(Net::SFTP).to receive(:start).with("hostname", "username", password: "password").and_return(sftp_session)
      allow(sftp_session).to receive(:upload!)
    end

    it 'move the invalid file to marc_ingest/failures' do
      # Originally I was adding YYYY-MM-DD to the moved file names but Alma actually already does this.
      # tar.gz files in Alma are named like:
      #   RDU_2024111001_59369796380006381_new.tar.gz
      #   RDU_2024111101_59411670300006381_new.tar.gz
      # so no need to add the date again.
      sftp = described_class.new
      sftp.upload_local_marc_file_to_remote_failures(local_file)

      expect(sftp_session).to have_received(:upload!).with(local_file, remote_failure_file)
    end
  end

  describe '#local_marc_processing_dir' do
    let(:scratch_space_path) { '/somewhere/scratch_space' }

    before do
      allow(Settings).to receive(:scratch_space_path).and_return(scratch_space_path)
      allow(FileUtils).to receive(:mkdir_p)
      allow(Dir).to receive(:exist?).and_return(false)
    end

    it 'returns the local MARC processing directory path' do
      sftp = described_class.new
      path = sftp.local_marc_processing_dir

      expect(path).to eq('/somewhere/scratch_space/marc_processing')
      expect(FileUtils).to have_received(:mkdir_p).with('/somewhere/scratch_space/marc_processing').twice
    end
  end
end
