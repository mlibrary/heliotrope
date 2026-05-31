require 'spec_helper'

describe Hydra::Works::AddFileToFileSet do
  let(:file_set)            { Hydra::Works::FileSet.new }
  let(:filename)            { 'sample-file.pdf' }
  let(:filename2)           { 'updated-file.txt' }
  let(:original_name)       { 'original-name.pdf' }
  let(:file)                { File.open(File.join(fixture_path, filename)) }
  let(:file2)               { File.open(File.join(fixture_path, filename2)) }
  let(:type)                { ::RDF::URI('http://pcdm.org/use#ExtractedText') }
  let(:update_existing)     { true }
  let(:mime_type)           { 'application/pdf' }

  context 'when file_set is not persisted' do
    let(:file_set) { Hydra::Works::FileSet.new }
    it 'saves file_set' do
      described_class.call(file_set, file, type)
      expect(file_set.persisted?).to be true
    end
  end

  context 'when file_set is not valid' do
    before do
      file_set.save
      allow(file_set).to receive(:valid?).and_return(false)
    end
    it 'returns false' do
      expect(described_class.call(file_set, file, type)).to be false
    end
  end

  context 'file responds to :mime_type and :original_name' do
    before do
      allow(file).to receive(:mime_type).and_return(mime_type)
      allow(file).to receive(:original_name).and_return(original_name)
      described_class.call(file_set, file, type)
    end
    subject { file_set.filter_files_by_type(type).first }
    it 'uses the mime_type and original_name methods' do
      expect(subject.mime_type).to eq(mime_type)
      expect(subject.original_name).to eq(original_name)
    end
  end

  context 'fall back on :original_filename and application/octet-stream' do
    before do
      allow(file).to receive(:original_filename).and_return('original_filename.tif')
      described_class.call(file_set, file, type)
    end
    subject { file_set.filter_files_by_type(type).first }
    it 'falls back on original_filename' do
      expect(subject.original_name).to eq('original_filename.tif')
    end
  end

  context 'when the file does not support any of the methods' do
    let(:file3) { instance_double(File) }
    before do
      allow(file3).to receive(:read).and_return('')
      allow(file3).to receive(:size).and_return(0)
      described_class.call(file_set, file3, type)
    end
    subject { file_set.filter_files_by_type(type).first }
    it 'falls back on "" and "application/octet-stream"' do
      expect(subject.mime_type).to eq('application/octet-stream')
      expect(subject.original_name).to eq('')
    end
  end

  context 'when determining mime type and name' do
    it 'uses services to assign the values' do
      expect(Hydra::Works::DetermineOriginalName).to receive(:call).with(file)
      expect(Hydra::Works::DetermineMimeType).to receive(:call).with(file, nil)
      described_class.call(file_set, file, type)
    end
  end

  it 'adds the given file and applies the specified type to it' do
    described_class.call(file_set, file, type, update_existing: update_existing)
    expect(file_set.filter_files_by_type(type).first.content).to start_with('%PDF-1.3')
  end

  context 'when :type is the name of an association' do
    let(:type)  { :extracted_text }
    before do
      described_class.call(file_set, file, type)
    end
    it "builds and uses the association's target" do
      expect(file_set.extracted_text.content).to start_with('%PDF-1.3')
    end
  end

  context 'when :versioning => true' do
    let(:type)        { :original_file }
    let(:versioning)  { true }
    subject     { file_set }
    it 'updates the file and creates a version' do
      described_class.call(file_set, file, type, versioning: versioning)
      expect(subject.original_file.versions.all.count).to eq(1)
      expect(subject.original_file.content).to start_with('%PDF-1.3')
    end
    context 'and there are already versions' do
      before do
        described_class.call(file_set, file, type, versioning: versioning)
        described_class.call(file_set, file2, type, versioning: versioning)
      end
      it 'adds to the version history' do
        expect(subject.original_file.versions.all.count).to eq(2)
        expect(subject.original_file.content).to eq("some updated content\n")
      end
    end
  end

  context 'when :versioning => false' do
    let(:type)        { :original_file }
    let(:versioning)  { false }
    before do
      described_class.call(file_set, file, type, versioning: versioning)
    end
    subject { file_set }
    it 'skips creating versions' do
      expect(subject.original_file.versions.all.count).to eq(0)
      expect(subject.original_file.content).to start_with('%PDF-1.3')
    end
  end

  context 'type_to_uri' do
    subject { Hydra::Works::AddFileToFileSet::Updater.allocate }
    it 'converts URI strings to RDF::URI' do
      expect(subject.send(:type_to_uri, 'http://example.com/CustomURI')).to eq(::RDF::URI('http://example.com/CustomURI'))
    end

    it 'returns an error for an invalid type' do
      expect(-> { subject.send(:type_to_uri, 0) }).to raise_error(ArgumentError, 'Invalid file type.  You must submit a URI or a symbol.')
    end
  end
end
