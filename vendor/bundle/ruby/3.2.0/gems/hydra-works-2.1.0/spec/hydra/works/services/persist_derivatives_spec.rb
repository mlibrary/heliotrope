require 'spec_helper'
require 'support/file_set_helper'

describe Hydra::Works::PersistDerivative do
  describe 'integration test' do
    let(:file_set) { Hydra::Works::FileSet.new }
    before do
      skip 'external tools not installed for CI environment' if ENV['CI']

      allow(file_set).to receive(:mime_type).and_return('video/x-msvideo')
      file_name = 'countdown.avi'
      original = File.new(File.join(fixture_path, file_name))
      Hydra::Works::UploadFileToFileSet.call(file_set, original)
      file_set.save!
    end

    it 'creates a thumbnail from original stored in fedora and persists to fedora' do
      file_set.create_derivatives
      expect(file_set.thumbnail).to have_content
      expect(file_set.thumbnail.mime_type).to eq('image/jpeg')
      expect(file_set.thumbnail.persisted?).to be true
    end
  end

  describe 'thumbnail generation' do
    before do
      file_content = IO.read(File.join(fixture_path, file_name))
      file = Hydra::PCDM::File.new do |f|
        f.content = file_content
        f.mime_type = mime_type
      end

      mock_add_file_to_file_set(file_set, file)
      allow(file).to receive(:mime_type).and_return(mime_type)
      # Mock .save to permit tests to run without hitting fedora persistence layer
      allow(file_set).to receive(:save).and_return(file_set)
    end

    context 'with a video (.avi) file' do
      let(:mime_type) { 'video/x-msvideo' }
      let(:file_name) { 'countdown.avi' }
      let(:file_set) { Hydra::Works::FileSet.create(id: '01/00') }

      it 'lacks a thumbnail' do
        expect(file_set.thumbnail).to be_nil
      end

      it 'generates a thumbnail derivative', unless: ENV['CI'] do
        file_set.create_derivatives
        expect(file_set.thumbnail).to have_content
        expect(file_set.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with an image file' do
      let(:mime_type) { 'image/png' }
      let(:file_name) { 'world.png' }
      let(:file_set) { Hydra::Works::FileSet.create(id: '01/01') }

      it 'lacks a thumbnail' do
        expect(file_set.thumbnail).to be_nil
      end

      # For Ruby 2.5.z releases, the following error is found within CircleCI environments:
      # `gm mogrify: Unrecognized option (-flatten)`
      xit 'uses PersistDerivative service to generate a thumbnail derivative' do
        file_set.create_derivatives
        expect(Hydra::Derivatives.output_file_service).to eq(described_class)
        expect(file_set.thumbnail).to have_content
        expect(file_set.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with an audio (.wav) file' do
      let(:mime_type) { 'audio/wav' }
      let(:file_name) { 'piano_note.wav' }
      let(:file_set) { Hydra::Works::FileSet.create(id: '01/02') }

      it 'lacks a thumbnail' do
        expect(file_set.thumbnail).to be_nil
      end

      it 'does not generate a thumbnail when derivatives are created', unless: ENV['CI'] do
        file_set.create_derivatives
        expect(file_set.thumbnail).to be_nil
      end
    end

    context 'with an image (.jp2) file' do
      let(:mime_type) { 'image/jp2' }
      let(:file_name) { 'image.jp2' }
      let(:file_set) { Hydra::Works::FileSet.create(id: '01/03') }

      it 'lacks a thumbnail' do
        expect(file_set.thumbnail).to be_nil
      end

      # This needs to be enabled once ImageMagick can be built with JPEG2000 support in CircleCI containers
      # The following error is raised:
      # `identify-im6.q16: no decode delegate for this image format `JP2' @ error/constitute.c/ReadImage/560.`
      xit 'generates a thumbnail on job run' do
        file_set.create_derivatives
        expect(file_set.thumbnail).to have_content
        expect(file_set.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with an office document (.docx) file' do
      let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
      let(:file_name) { 'charter.docx' }
      let(:file_set) { Hydra::Works::FileSet.create(id: '01/04') }

      it 'lacks a thumbnail' do
        expect(file_set.thumbnail).to be_nil
      end

      it 'generates a thumbnail on job run', unless: ENV['CI'] do
        pending 'regression: investigate updates to Hydra::Derivatives and refactor where appropriate.'
        file_set.create_derivatives
        expect(file_set.thumbnail).to have_content
        expect(file_set.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with a pdf document (.pdf) file' do
      let(:mime_type) { 'application/pdf' }
      let(:file_name) { 'sample-file.pdf' }
      let(:file_set) { Hydra::Works::FileSet.create(id: '01/05') }

      it 'lacks a thumbnail' do
        expect(file_set.thumbnail).to be_nil
      end

      it 'generates a thumbnail on job run', unless: ENV['CI'] do
        file_set.create_derivatives
        expect(file_set.thumbnail).to have_content
        expect(file_set.thumbnail.mime_type).to eq('image/jpeg')
      end
    end
  end

  describe 'mime type guessing' do
    it 'has hard-coded mime types for mp4 and webm' do
      expect(described_class.new_mime_type('mp4')).to eq('video/mp4')
      expect(described_class.new_mime_type('webm')).to eq('video/webm')
    end
  end
end
