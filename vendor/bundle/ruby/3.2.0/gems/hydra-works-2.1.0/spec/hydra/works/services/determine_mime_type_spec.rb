require 'spec_helper'

describe Hydra::Works::DetermineMimeType do
  let(:original_name) { nil }
  let(:file) { File.open(File.join(fixture_path, 'sample-file.pdf')) }

  subject { described_class.call(file, original_name) }

  context "when file has :mime_type" do
    before { allow(file).to receive(:mime_type).and_return("mime_type") }
    it { is_expected.to eq("mime_type") }
  end

  context "when file has :content_type" do
    before { allow(file).to receive(:content_type).and_return("content_type") }
    it { is_expected.to eq("content_type") }
  end

  context "when file has :path" do
    it { is_expected.to eq("application/pdf") }
  end

  context "when an original_name is supplied" do
    let(:original_name) { "some-other-file.txt" }
    it { is_expected.to eq("text/plain") }
  end

  context "when an empty original_name is supplied" do
    let(:original_name) { "" }
    it { is_expected.to eq("application/pdf") }
  end

  context "when all else fails" do
    before do
      allow(file).to receive(:respond_to?).with(:mime_type).and_return(false)
      allow(file).to receive(:respond_to?).with(:content_type).and_return(false)
      allow(file).to receive(:respond_to?).with(:path).and_return(false)
    end
    it { is_expected.to eq("application/octet-stream") }
  end
end
