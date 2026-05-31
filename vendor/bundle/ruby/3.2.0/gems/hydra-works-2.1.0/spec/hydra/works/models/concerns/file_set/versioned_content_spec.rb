require 'spec_helper'

describe Hydra::Works::VersionedContent do
  let(:file_set) { Hydra::Works::FileSet.new }
  before do
    Hydra::Works::UploadFileToFileSet.call(file_set, File.open(File.join(fixture_path, 'sample-file.pdf')))
    Hydra::Works::UploadFileToFileSet.call(file_set, File.open(File.join(fixture_path, 'updated-file.txt')))
  end

  describe 'content_versions' do
    subject { file_set.content_versions }
    it 'lists all of the versions of original_file' do
      expect(subject.count).to eq(2)
      expect(subject.map(&:uri)).to eq(file_set.original_file.versions.all.map(&:uri))
    end
  end

  describe 'latest_content_version' do
    subject { file_set.latest_content_version }
    it 'returns the most recent version entry for original_file' do
      # Can't use a simple equivalence because they are actually different ResourceVersion objects
      expect(subject.uri).to eq(file_set.original_file.versions.last.uri)
      expect(subject.label).to eq(file_set.original_file.versions.last.label)
    end
  end

  describe 'current_content_version_uri' do
    it 'returns the URI of the most recent version of original_file' do
      expect(file_set.current_content_version_uri).to eq(file_set.original_file.versions.last.uri)
    end
  end
end
