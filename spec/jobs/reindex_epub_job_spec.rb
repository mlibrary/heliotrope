# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexEpubJob, type: :job do
  describe "perform" do
    let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
    let(:db_file) { File.join(UnpackService.root_path_from_noid(epub.id, 'epub'), epub.id + '.db') }

    before do
      UnpackJob.perform_now(epub.id, 'epub')
    end

    it "reindexes the epub" do
      # The only thing that will really change here is the timestamp on the
      # .db sqlite file. So I guess test that
      old_timestamp = File.mtime(db_file).to_f
      old_size = File.size(db_file)
      described_class.perform_now(epub.id)
      expect(old_timestamp <= File.mtime(db_file).to_f).to be true
      # Make sure the contents are the same
      expect(old_size == File.size(db_file)).to be true
    end

    context 'SQLite3 Exception' do
      let(:logger) { instance_double(ActiveSupport::Logger, 'logger') }

      before do
        allow(EPub::SqlLite).to receive(:from_directory).with(anything).and_raise(SQLite3::Exception)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error).with("EPub Index #{db_file} not updated")
        allow(logger).to receive(:error).with("SQLite3::Exception")
      end

      it 'logs error' do
        described_class.perform_now(epub.id)
        expect(logger).to have_received(:error).with("EPub Index #{db_file} not updated")
        expect(logger).to have_received(:error).with("SQLite3::Exception")
      end
    end
  end
end
