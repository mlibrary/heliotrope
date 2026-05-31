require 'spec_helper'

describe Hydra::PCDM::GetMimeTypeForFile do
  context 'with faulty input' do
    let(:error_message) { 'supplied argument should be a path to a file' }
    it 'raises and error' do
      expect(-> { described_class.call(['bad input']) }).to raise_error(ArgumentError, error_message)
    end
  end

  context 'with a standard file type' do
    subject    { described_class.call(path) }
    let(:path) { '/path/file.jpg' }

    it { is_expected.to eql 'image/jpeg' }
  end

  context 'with an unknown file type' do
    subject    { described_class.call(path) }
    let(:path) { '/path/file.jkl' }

    it { is_expected.to eql 'application/octet-stream' }
  end
end
