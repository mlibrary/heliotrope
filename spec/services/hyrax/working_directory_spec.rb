# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::WorkingDirectory do
  let(:file) { instance_double(Hydra::PCDM::File, original_name: 'video.mov', id: 'repository-file', stream: stream) }
  let(:stream) { [first_chunk, last_chunk].each }
  let(:first_chunk) { "\x00\xFF".b * 16_384 }
  let(:last_chunk) { "\x80last chunk".b }
  let(:working_path) { File.join(@working_directory, 'qr', '46', 'r1', '17', 'qr46r117n', 'video.mov') }

  around do |example|
    Dir.mktmpdir do |directory|
      @working_directory = directory
      example.run
    end
  end

  before do
    allow(Hyrax.config).to receive(:working_path).and_return(@working_directory)
  end

  describe '.copy_repository_resource_to_working_directory' do
    subject(:copy) { described_class.copy_repository_resource_to_working_directory(file, 'qr46r117n') }

    it 'writes binary chunks without loading the complete content' do
      expect(file).not_to receive(:content)

      expect(copy).to eq working_path
      expect(File.binread(working_path)).to eq(first_chunk + last_chunk)
      expect(Dir.children(File.dirname(working_path))).to eq ['video.mov']
    end

    context 'while streaming' do
      let(:stream) do
        Enumerator.new do |chunks|
          chunks << first_chunk
          download = Dir.glob(File.join(File.dirname(working_path), 'repository-download*')).first
          expect(File.binread(download)).to eq first_chunk
          expect(File).not_to exist(working_path)
          chunks << last_chunk
        end
      end

      it 'writes each chunk before requesting the next' do
        copy

        expect(File.binread(working_path)).to eq(first_chunk + last_chunk)
      end
    end

    context 'when a working copy already exists' do
      before do
        FileUtils.mkdir_p(File.dirname(working_path))
        File.binwrite(working_path, 'old content')
      end

      it 'replaces it with the latest repository content' do
        copy

        expect(File.binread(working_path)).to eq(first_chunk + last_chunk)
      end
    end

    context 'when the download fails' do
      let(:stream) do
        Enumerator.new do |chunks|
          chunks << first_chunk
          raise IOError, 'download interrupted'
        end
      end

      it 'propagates the error and removes the incomplete download' do
        expect { copy }.to raise_error(IOError, 'download interrupted')

        expect(Dir.children(File.dirname(working_path))).to be_empty
      end

      it 'leaves an existing working copy unchanged' do
        FileUtils.mkdir_p(File.dirname(working_path))
        File.binwrite(working_path, 'old content')

        expect { copy }.to raise_error(IOError, 'download interrupted')

        expect(File.binread(working_path)).to eq 'old content'
        expect(Dir.children(File.dirname(working_path))).to eq ['video.mov']
      end
    end

    context 'with a repository file' do
      let(:file) do
        Hydra::PCDM::File.new do |repository_file|
          repository_file.content = first_chunk + last_chunk
          repository_file.original_name = 'video.mov'
          repository_file.save!
        end
      end

      it 'streams the binary through the authenticated ActiveFedora API' do
        file
        expect(file).not_to receive(:content)

        copy

        expect(File.binread(working_path)).to eq(first_chunk + last_chunk)
      end
    end
  end
end
