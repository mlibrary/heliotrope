require 'spec_helper'

describe Hydra::Works::AddExternalFileToFileSet do
  let(:file_set)            { Hydra::Works::FileSet.new }
  let(:file_set2)           { Hydra::Works::FileSet.new }
  let(:filename)            { 'sample-file.pdf' }
  let(:filename2)           { 'updated-file.txt' }
  let(:original_name)       { 'original-name.pdf' }
  # let(:file)                { File.open(File.join(fixture_path, filename)) }
  # let(:file2)               { File.open(File.join(fixture_path, filename2)) }
  let(:external_file_url)   { "http://foo.org/abc1234" }
  let(:type)                { ::RDF::URI('http://pcdm.org/use#ExtractedText') }
  let(:update_existing)     { true }
  # let(:mime_type)           { 'application/pdf' }

  context 'when file_set is not persisted' do
    let(:file_set) { Hydra::Works::FileSet.new }
    it 'saves file_set' do
      described_class.call(file_set, external_file_url, type)
      expect(file_set.persisted?).to be true
    end
  end

  context 'when file_set is not valid' do
    before do
      file_set.save
      allow(file_set).to receive(:valid?).and_return(false)
    end
    it 'returns false' do
      expect(described_class.call(file_set, external_file_url, type)).to be false
    end
  end

  context 'when file set is valid' do
    before do
      described_class.call(file_set, external_file_url, type, filename: original_name)
    end

    subject(:file) { file_set.filter_files_by_type(type).first }

    it 'sets mime type of the File object to message/external body containing external file URL' do
      expect(file.mime_type).to eq "message/external-body;access-type=URL;url=\"http://foo.org/abc1234\""
    end

    it 'assigns value of :filename option to the File object' do
      expect(file.original_name).to eq original_name
    end

    context 'when no filename is passed in' do
      before do
        described_class.call(file_set, external_file_url, type)
      end

      subject(:file) { file_set.filter_files_by_type(type).last }

      it 'sets filename of File objectd to be the same as the external file url' do
        expect(file.original_name).to eq external_file_url
      end
    end
  end
end
