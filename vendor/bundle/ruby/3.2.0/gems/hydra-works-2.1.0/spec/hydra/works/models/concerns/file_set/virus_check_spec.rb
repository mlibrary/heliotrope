require 'spec_helper'

describe Hydra::Works::VirusCheck do
  context "with ClamAV" do
    subject { FileWithVirusCheck.new }
    let(:file) { Hydra::PCDM::File.new { |f| f.content = File.new(File.join(fixture_path, 'sample-file.pdf')) } }

    before do
      class FileWithVirusCheck < ActiveFedora::Base
        include Hydra::Works::FileSetBehavior
        include Hydra::Works::VirusCheck
      end
      allow(subject).to receive(:original_file) { file }
    end
    after do
      Object.send(:remove_const, :FileWithVirusCheck)
    end

    context 'with an infected file' do
      before do
        expect(Hydra::Works::VirusCheckerService).to receive(:file_has_virus?).and_return(true)
      end
      it 'fails to save' do
        expect(subject.save).to eq false
      end
      it 'fails to validate' do
        expect(subject.validate).to eq false
      end
    end

    context 'with a clean file' do
      before do
      end

      it 'does not detect viruses' do
        expect(Hydra::Works::VirusCheckerService).to receive(:file_has_virus?).and_return(false)
        expect(subject).not_to be_viruses
      end
    end
  end
end
