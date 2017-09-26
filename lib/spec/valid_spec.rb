# frozen_string_literal: true

RSpec.describe Valid do
  describe '#noid?' do
    subject { described_class.noid?(id) }

    context 'nil' do
      let(:id) { nil }
      it { is_expected.to be false }
    end
    context 'non String' do
      let(:id) { double('id') }
      it { is_expected.to be false }
    end
    context 'blank?' do
      let(:id) { '' }
      it { is_expected.to be false }
    end
    context 'invalid' do
      let(:id) { 'invalidnoid' }
      it { is_expected.to be false }
    end
    context 'valid' do
      let(:id) { 'validnoid' }
      it { is_expected.to be true }
    end
  end
end
