require 'spec_helper'

describe Hydra::Works::UploadFileToFileSet do
  let(:work) { Hydra::Works::Work.new }
  let(:file_set) { Hydra::Works::FileSet.new }
  let(:file) { File.open(File.join(fixture_path, 'sample-file.pdf')) }
  let(:updated_file) { File.open(File.join(fixture_path, 'updated-file.txt')) }
  let(:mime_type) { 'application/pdf' }
  let(:original_name) { 'my_original.pdf' }
  let(:updated_mime_type) { 'text/plain' }
  let(:updated_name) { 'my_updated.txt' }

  context 'when you provide mime_type and original_name, etc' do
    it 'uses the provided values' do
      expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(file_set, file, :original_file, update_existing: true, versioning: true)
      described_class.call(file_set, file)
    end
  end

  # Duplicate test from add_file_spec
  context 'without a proper file set' do
    let(:error_message) { 'supplied object must be a file set' }
    it 'raises an error' do
      expect(-> { described_class.call(work, file) }).to raise_error(ArgumentError, error_message)
    end
  end

  # Duplicate test from add_file_spec
  context 'without file that responds to read.' do
    let(:error_message) { 'supplied file must respond to read' }
    it 'raises an error' do
      expect(-> { described_class.call(file_set, ['this does not respond to read.']) }).to raise_error(ArgumentError, error_message)
    end
  end

  context 'with an empty file set' do
    let(:additional_services) { [] }
    before do
      allow(file).to receive(:mime_type).and_return(mime_type)
      allow(file).to receive(:original_name).and_return(original_name)
      described_class.call(file_set, file, additional_services: additional_services)
    end

    describe 'the uploaded file' do
      subject { file_set.original_file }
      it 'has updated properties' do
        expect(subject.content).to start_with('%PDF-1.3')
        expect(subject.mime_type).to eql mime_type
        expect(subject.original_name).to eql original_name
      end
    end

    describe "the file set's generated files" do
      subject { file_set }
      it 'has content and generated files' do
        expect(subject.original_file.content).to start_with('%PDF-1.3')
        expect(subject.original_file.mime_type).to eql mime_type
        expect(subject.original_file.original_name).to eql original_name
      end
    end
  end

  context 'with additional services' do
    let(:dummy_service) { double('service') }
    before do
      allow(file).to receive(:mime_type).and_return(mime_type)
      allow(file).to receive(:original_name).and_return(original_name)
    end

    describe 'additional services' do
      it 'gets called' do
        expect(dummy_service).to receive(:call)
        described_class.call(file_set, file, additional_services: [dummy_service])
      end
    end
  end

  context 'when updating an existing file' do
    let(:additional_services) { [] }
    before do
      allow(file).to receive(:mime_type).and_return(mime_type)
      allow(file).to receive(:original_name).and_return(original_name)
      allow(updated_file).to receive(:mime_type).and_return(updated_mime_type)
      allow(updated_file).to receive(:original_name).and_return(updated_name)

      described_class.call(file_set, file, additional_services: additional_services)
      described_class.call(file_set, updated_file, additional_services: additional_services, update_existing: true)
    end

    describe 'the new file' do
      subject { file_set.original_file }
      it 'has updated properties' do
        updated_file.rewind
        expect(subject.content).to eql updated_file.read
        expect(subject.original_name).to eql updated_name
        expect(subject.mime_type).to eql updated_mime_type
        expect(subject.versions.all.count).to eql 2
      end
    end
  end
end
