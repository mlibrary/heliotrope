require 'spec_helper'

describe Hydra::Works::DetermineOriginalName do
  let(:file) { File.open(File.join(fixture_path, 'sample-file.pdf')) }

  subject { described_class.call(file) }

  context "when file has :original_name" do
    before { allow(file).to receive(:original_name).and_return("original_name") }
    it { is_expected.to eq("original_name") }
  end

  context "when file has :original_filename" do
    before { allow(file).to receive(:original_filename).and_return("original_filename") }
    it { is_expected.to eq("original_filename") }
  end

  context "when file has :path" do
    it { is_expected.to eq("sample-file.pdf") }
  end

  context "when all else fails" do
    before do
      allow(file).to receive(:respond_to?).with(:original_name).and_return(false)
      allow(file).to receive(:respond_to?).with(:original_filename).and_return(false)
      allow(file).to receive(:respond_to?).with(:path).and_return(false)
    end
    it { is_expected.to be_empty }
  end
end
