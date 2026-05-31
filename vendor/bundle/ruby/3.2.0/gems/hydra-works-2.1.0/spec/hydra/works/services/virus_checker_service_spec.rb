require 'spec_helper'

describe Hydra::Works::VirusCheckerService do
  let(:system_virus_scanner) { double }
  let(:file) { Hydra::PCDM::File.new }
  let(:virus_checker) { described_class.new(file, system_virus_scanner) }
  let(:datastream) { instance_double "ActiveFedora::File::Streaming::FileBody" }
  let(:content) { instance_double "File" }

  before do
    allow(file).to receive(:stream).and_return(datastream)
    allow(file).to receive(:content).and_return(content)
    allow(datastream).to receive(:each)
  end

  context '.file_has_virus?' do
    it 'is a convenience method' do
      mock_object = instance_double(described_class, file_has_virus?: true)
      allow(described_class).to receive(:new).and_return(mock_object)
      described_class.file_has_virus?(file)
      expect(mock_object).to have_received(:file_has_virus?)
    end
  end

  context 'with an infected file' do
    context 'that responds to :path' do
      it 'will return true' do
        expect(system_virus_scanner).to receive(:infected?).with('/tmp/file.pdf').and_return(true)
        allow(file).to receive(:path).and_return('/tmp/file.pdf')
        expect(virus_checker.file_has_virus?).to eq(true)
      end
    end
    context 'that does not respond to :path' do
      let(:content) { instance_double "File", read: ["abc123", nil], rewind: true }
      it 'will return true' do
        expect(system_virus_scanner).to receive(:infected?).with(kind_of(String)).and_return(true)
        allow(file).to receive(:respond_to?).and_call_original
        allow(file).to receive(:respond_to?).with(:path).and_return(false)
        expect(virus_checker.file_has_virus?).to eq(true)
      end
    end
  end

  context 'with a clean unsaved file' do
    context 'that responds to :path' do
      it 'will return false' do
        expect(system_virus_scanner).to receive(:infected?).with('/tmp/file.pdf').and_return(false)
        allow(file).to receive(:path).and_return('/tmp/file.pdf')
        expect(virus_checker.file_has_virus?).to eq(false)
      end
    end

    context "that does not respond to path" do
      before do
        allow(file).to receive(:respond_to?).with(:path).and_return(false)
      end
      context 'that the content responds to path' do
        let(:content) { instance_double "File", read: ["abc123", nil], rewind: true, path: "abc123" }

        it 'will return false' do
          expect(system_virus_scanner).to receive(:infected?).with(kind_of(String)).and_return(false)
          expect(content).not_to receive(:read)
          expect(virus_checker.file_has_virus?).to eq(false)
        end
      end
      context "that the content does not respond to path" do
        let(:content) { instance_double "File", read: ["abc123", nil], rewind: true }
        it 'will return false' do
          expect(system_virus_scanner).to receive(:infected?).with(kind_of(String)).and_return(false)
          expect(file).not_to receive(:stream)
          expect(virus_checker.file_has_virus?).to eq(false)
        end
      end
    end
  end

  context "with a clean saved file that does not respond to :path" do
    before do
      allow(file).to receive(:new_record?).and_return(false)
    end
    context 'that does not respond to :path' do
      it 'will return false' do
        expect(system_virus_scanner).to receive(:infected?).with(kind_of(String)).and_return(false)
        expect(content).not_to receive(:read)
        allow(file).to receive(:respond_to?).and_call_original
        allow(file).to receive(:respond_to?).with(:path).and_return(false)
        expect(virus_checker.file_has_virus?).to eq(false)
      end
    end
  end
end
