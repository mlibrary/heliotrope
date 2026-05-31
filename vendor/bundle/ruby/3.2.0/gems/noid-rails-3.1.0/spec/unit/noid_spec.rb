# frozen_string_literal: true

RSpec.describe Noid::Rails do
  describe '#configure' do
    it { is_expected.to respond_to(:configure) }
  end

  describe '#config' do
    it 'returns a config object' do
      expect(subject.config).to be_instance_of Noid::Rails::Config
    end
  end

  describe '#treeify' do
    subject { described_class.treeify(id) }

    let(:id) { 'abc123def45' }

    it { is_expected.to eq 'ab/c1/23/de/abc123def45' }

    context 'with a seven-digit identifier' do
      let(:id) { 'abc123z' }

      it { is_expected.to eq 'ab/c1/23/z/abc123z' }
    end

    context 'with an empty string' do
      let(:id) { '' }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with a nil' do
      let(:id) { nil }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end
end
