# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Riiif::KakaduTransformer do
  subject(:instance) { described_class.new(path, image_info, transformation) }

  let(:image_info) { Riiif::ImageInformation.new(width: 6501, height: 4381) }
  let(:path) { 'baseball.jp2' }
  let(:region) { IIIF::Image::Region::Full.new }
  let(:size) { IIIF::Image::Size::Full.new }
  let(:quality) { nil }
  let(:rotation) { 0 }
  let(:fmt) { 'jpg' }

  let(:transformation) do
    IIIF::Image::Transformation.new(region: region,
                                    size: size,
                                    quality: quality,
                                    rotation: rotation,
                                    format: fmt)
  end

  describe '#transform' do
    let(:image_data) { double }

    subject(:transform) { instance.transform }

    before do
      allow(instance).to receive(:with_tempfile).and_yield('/tmp/foo.bmp')
    end

    context 'resize and region' do
      # This is the validator test for size_region
      let(:size) { IIIF::Image::Size::Absolute.new(38, 38) }
      let(:region) { IIIF::Image::Region::Absolute.new(200, 100, 100, 100) }

      let(:image_info) { Riiif::ImageInformation.new(width: 1000, height: 1000) }

      it 'calls the Imagemagick transform' do
        expect(Riiif::CommandRunner).to receive(:execute)
          .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 ' \
                '-region "{0.1,0.2},{0.1,0.1}" -reduce 4 -o /tmp/foo.bmp')
        expect(Riiif::CommandRunner).to receive(:execute)
          .with('convert -resize 38x38! -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
        transform
      end
    end

    context 'when reduction_factor is 0' do
      let(:reduction_factor) { 0 }
      context 'and the size is full' do
        it 'calls the Imagemagick transform' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 -o /tmp/foo.bmp')
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('convert -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
          transform
        end
      end

      context 'and size is a width' do
        let(:size) { IIIF::Image::Size::Width.new(651) }
        let(:image_info) { Riiif::ImageInformation.new(width: 1000, height: 1000) }

        it 'calls the Imagemagick transform' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 -o /tmp/foo.bmp')
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('convert -resize 651 -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
          transform
        end
      end

      context 'and size is a height' do
        let(:size) { IIIF::Image::Size::Height.new(581) }
        let(:image_info) { Riiif::ImageInformation.new(width: 1000, height: 1000) }

        it 'calls the Imagemagick transform' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 -o /tmp/foo.bmp')
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('convert -resize x581 -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
          transform
        end
      end
    end

    context 'when reduction_factor is 1' do
      let(:reduction_factor) { 1 }

      context 'and size is a Percent' do
        let(:size) { IIIF::Image::Size::Percent.new(30.0) }

        it 'calls the Imagemagick transform' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 -reduce 1 -o /tmp/foo.bmp')
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('convert -resize 60.0% -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
          transform
        end
      end

      context 'and size is a width' do
        let(:size) { IIIF::Image::Size::Width.new(408) }
        let(:image_info) { Riiif::ImageInformation.new(width: 1000, height: 1000) }

        it 'calls the Imagemagick transform' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 -reduce 1 -o /tmp/foo.bmp')
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('convert -resize 408 -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
          transform
        end
      end

      context 'and size is a height' do
        let(:size) { IIIF::Image::Size::Height.new(481) }
        let(:image_info) { Riiif::ImageInformation.new(width: 1000, height: 1000) }

        it 'calls the Imagemagick transform' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 -reduce 1 -o /tmp/foo.bmp')
          expect(Riiif::CommandRunner).to receive(:execute)
            .with('convert -resize x481 -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
          transform
        end
      end
    end

    context 'when reduction_factor is 2' do
      let(:size) { IIIF::Image::Size::Percent.new(20.0) }
      let(:reduction_factor) { 2 }
      it 'calls the Imagemagick transform' do
        expect(Riiif::CommandRunner).to receive(:execute)
          .with('kdu_expand -quiet -i baseball.jp2 -num_threads 4 -reduce 2 -o /tmp/foo.bmp')
        expect(Riiif::CommandRunner).to receive(:execute)
          .with('convert -resize 80.0% -quality 85 -sampling-factor 4:2:0 -strip \'/tmp/foo.bmp\' jpg:-')
        transform
      end
    end
  end
end
