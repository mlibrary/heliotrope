require 'spec_helper'

RSpec.describe Riiif::ImageInformation do
  describe '#valid?' do
    subject { info.valid? }

    context 'with valid dimensions' do
      let(:info) { described_class.new(width: 100, height: 200) }

      it { is_expected.to be true }
    end

    context 'with nil dimensions' do
      let(:info) { described_class.new(width: nil, height: nil) }

      it { is_expected.to be false }
    end
  end
end
