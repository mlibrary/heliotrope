RSpec.describe Riiif::File do
  describe '#info_extractor_class' do
    subject { described_class.info_extractor_class }

    context 'when not using vips' do
      it { is_expected.to eq Riiif::ImageMagickInfoExtractor }
    end

    context 'when vips is configured' do
      before { allow(Riiif).to receive(:use_vips?).and_return true }

      it { is_expected.to eq Riiif::VipsInfoExtractor }
    end
  end

  describe '#transformer' do
    subject { described_class.new('path.jp2', double).transformer }

    context 'when vips is configured' do
      before { allow(Riiif).to receive(:use_vips?).and_return true }

      it { is_expected.to eq Riiif::VipsTransformer }
    end

    context 'when Kakadu is enabled' do
      before { allow(Riiif).to receive(:kakadu_enabled?).and_return true }

      it { is_expected.to eq Riiif::KakaduTransformer }
    end

    context 'when using image/graphicsmagick without Kakadu' do
      it { is_expected.to eq Riiif::ImagemagickTransformer }
    end
  end
end
