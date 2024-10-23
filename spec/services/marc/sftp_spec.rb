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

      # This is odd but otherwise @conn leaks between specs!
      after { described_class.instance_variable_set("@conn", nil) }

      it "starts the Net::SFTP session" do
        conn = described_class.conn
        expect(conn).to be(sftp_session)
      end
    end

    context "when config is not present" do
      before do
        allow(Marc::Sftp).to receive(:yaml_config).and_return(nil)
        allow(MarcLogger).to receive(:error)
      end

      it 'logs an error and returns nil' do
        conn = described_class.conn
        expect(conn).to be_nil
        expect(MarcLogger).to have_received(:error).with("No ftp.fulcrum.org credentials present!")
      end
    end

    context 'when an exception occurs' do
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

      before do
        allow(Rails.root).to receive(:join).with('config', 'fulcrum_sftp.yml').and_return(config)
        allow(File).to receive(:exist?).with(config).and_return(true)
        allow(File).to receive(:read).with(config).and_return(true)
        allow(YAML).to receive(:safe_load).and_return valid_yaml

        allow(Net::SFTP).to receive(:start).and_raise(Net::SSH::Disconnect.new('connection error'))
        allow(MarcLogger).to receive(:error)
      end

      it 'logs the exception and returns nil' do
        conn = described_class.conn

        expect(conn).to be_nil
        expect(MarcLogger).to have_received(:error).with(instance_of(Net::SSH::Disconnect))
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

      allow(Marc::Sftp).to receive(:local_marc_processing_dir).and_return(local_marc_processing_dir)
      allow(FileUtils).to receive(:mkdir_p)
      allow(sftp_session).to receive(:dir).and_return(sftp_dir)
      allow(sftp_dir).to receive(:foreach).with("/home/fulcrum_ftp/marc_ingest").and_yield(file_entry)
      allow(sftp_session).to receive(:download!)
    end

    after { described_class.instance_variable_set("@conn", nil) }

    it 'downloads files from the SFTP server and saves them locally' do
      files = described_class.download_marc_ingest_files

      expect(sftp_session).to have_received(:download!).with("/home/fulcrum_ftp/marc_ingest/test_file.mrc", "#{local_marc_processing_dir}/test_file.mrc")
      expect(files).to include("#{local_marc_processing_dir}/test_file.mrc")
    end
  end

  describe '#move_marc_ingest_file_to_product_dir' do
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
      allow(sftp_session).to receive(:rename!)
    end

    after { described_class.instance_variable_set("@conn", nil) }

    it 'moves a file to the specified directory on the SFTP server' do
      described_class.move_marc_ingest_file_to_product_dir('test_file.mrc', '/home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC')

      expect(sftp_session).to have_received(:rename!).with("/home/fulcrum_ftp/marc_ingest/test_file.mrc", "/home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC/test_file.mrc")
    end
  end

  describe '.remove_marc_ingest_file' do
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

    after { described_class.instance_variable_set("@conn", nil) }

    it 'removes a file from the SFTP server' do
      described_class.remove_marc_ingest_file('test_file.mrc')

      expect(sftp_session).to have_received(:remove!).with("/home/fulcrum_ftp/marc_ingest/test_file.mrc")
    end
  end

  describe "#move_marc_ingest_file_to_failures" do
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
      allow(sftp_session).to receive(:rename!)
    end

    after { described_class.instance_variable_set("@conn", nil) }

    it 'renames an invalid marc with YYYY-MM-DD and moves it to marc_ingest/failures' do
      travel_to(Time.zone.local(2022, 02, 02, 12, 00, 00)) do
        described_class.move_marc_ingest_file_to_failures('/local/path/to/test_file.mrc')
        expect(sftp_session).to have_received(:rename!).with("/home/fulcrum_ftp/marc_ingest/test_file.mrc", "/home/fulcrum_ftp/marc_ingest/failures/2022-02-02_test_file.mrc")
      end
    end
  end

  describe '.local_marc_processing_dir' do
    let(:scratch_space_path) { '/somewhere/scratch_space' }

    before do
      allow(Settings).to receive(:scratch_space_path).and_return(scratch_space_path)
      allow(FileUtils).to receive(:mkdir_p)
      allow(Dir).to receive(:exist?).and_return(false)
    end

    it 'returns the local MARC processing directory path' do
      path = described_class.local_marc_processing_dir

      expect(path).to eq('/somewhere/scratch_space/marc_processing')
      expect(FileUtils).to have_received(:mkdir_p).with('/somewhere/scratch_space/marc_processing')
    end
  end
end
