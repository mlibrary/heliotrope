require 'spec_helper'

begin
  require 'ruby-vips'
rescue LoadError
  module Vips
    class Image
      # Intentionally blank.
      #
      # This prevents uninitialized constant errors if vips
      # is not installed.
    end
  end
end

RSpec.describe Riiif::VipsTransformer do
  let(:channels) { 'rgb' }

  let(:path) { "path/to/image.tif" }

  let(:image) { double('Vips Image', has_alpha?: false) }

  let(:image_info) do
    double({ height: 376,
             width: 500,
             format: 'jpg',
             channels: channels })
  end

  let(:target) { 'jpg' }

  let(:transformation) do
    IIIF::Image::Transformation.new(region: region,
                                    size: size,
                                    rotation: rotation,
                                    format: target)
  end

  # Default/Placeholder values that should be modified in tests
  let(:size) { IIIF::Image::Size::Full.new }
  let(:region) { IIIF::Image::Region::Full.new }
  let(:rotation) { 0 }

  before do
    allow(Vips::Image).to receive(:new_from_file).and_return(image)
  end

  describe '#initialize' do
    let(:path) { Pathname.new("path/to/image.tif") }

    it 'normalizes pathnames to strings' do
      expect(Vips::Image).to receive(:new_from_file).with("path/to/image.tif")
      described_class.new(path, image_info, transformation)
    end
  end

  describe '#transform' do
    subject { described_class.new(path, image_info, transformation).transform }
    before { allow(image).to receive(:write_to_buffer) }
    after { subject }

    context 'when requesting jpg format with default options' do
      it 'writes to jpg format' do
        expect(image).to receive(:write_to_buffer).with(".jpg[Q=85,optimize-coding,strip]")
      end
    end

    context 'when requesting png format with default options' do
      let(:target) { 'png' }

      it 'writes to png format' do
        expect(image).to receive(:write_to_buffer).with(".png[Q=85,strip]")
      end
    end

    context 'when requesting jpeg format for a png' do
      let(:image) { double('Vips Image', has_alpha?: true) }

      it 'writes to png anyway to preserve transparency' do
        expect(image).to receive(:write_to_buffer).with(".png[Q=85,strip]")
      end
    end

    context 'with subsampling turned off' do
      subject { described_class.new(path, image_info, transformation, subsample: false).transform }

      it 'does not subsample' do
        expect(image).to receive(:write_to_buffer).with(".jpg[Q=85,optimize-coding,strip,no-subsample]")
      end
    end

    context 'when specifying compression factor' do
      subject { described_class.new(path, image_info, transformation, compression: 90).transform }

      it 'compresses to the correct quality' do
        expect(image).to receive(:write_to_buffer).with(".jpg[Q=90,optimize-coding,strip]")
      end
    end

    context 'when strip_metadata is false' do
      subject { described_class.new(path, image_info, transformation, strip_metadata: false).transform }

      it 'does not strip metadata' do
        expect(image).to receive(:write_to_buffer).with(".jpg[Q=85,optimize-coding]")
      end
    end
  end

  describe '#transform_image' do
    subject { described_class.new(path, image_info, transformation).send(:transform_image) }

    before do
      allow(image).to receive_messages(crop: image, resize: image, rotate: image, thumbnail_image: image, colourspace: image)
    end

    describe 'resize' do
      context 'when specifing full size' do
        it 'does not resize' do
          expect(image).not_to receive(:resize)
          expect(image).not_to receive(:thumbnail_image)
          subject
        end
      end

      context 'when specifing percent size' do
        let(:size) { IIIF::Image::Size::Percent.new(50) }

        it 'resizes the image' do
          expect(image).to receive(:resize).with(50.0)
          expect(image).not_to receive(:thumbnail_image)
          subject
        end
      end

      context 'when specifing float percent size' do
        let(:size) { IIIF::Image::Size::Percent.new(12.5) }

        it 'resizes the image' do
          expect(image).to receive(:resize).with(12.5)
          expect(image).not_to receive(:thumbnail_image)
          subject
        end
      end

      context 'when specifying width and/or height' do
        context 'when specifing w, size' do
          let(:size) { IIIF::Image::Size::Width.new(300) }

          before { allow(image).to receive(:width).and_return(600) }

          it 'resizes the image to 300px wide, maintaining aspect ratio' do
            expect(image).to receive(:resize).with(0.5)
            subject
          end
        end

        context 'when specifing ,h size' do
          let(:size) { IIIF::Image::Size::Height.new(200) }

          before { allow(image).to receive(:height).and_return(500) }

          it 'resizes the image to 300px high, maintaining aspect ratio' do
            expect(image).to receive(:resize).with(0.4)
            subject
          end
        end

        context 'when specifing absolute w,h size' do
          let(:size) { IIIF::Image::Size::Absolute.new(200, 300) }

          it 'resizes the image, ignoring aspect ratio' do
            expect(image).to receive(:thumbnail_image).with(200, height: 300, size: :force)
            subject
          end
        end

        context 'when specifing bestfit (!w,h) size' do
          let(:size) { IIIF::Image::Size::BestFit.new(200, 300) }

          it 'resizes the image so that the width and height are equal or less than the requested value' do
            expect(image).to receive(:thumbnail_image).with(200, height: 300)
            subject
          end
        end
      end
    end

    describe 'crop' do
      after { subject }

      context 'when specifing full size' do
        let(:region) { IIIF::Image::Region::Full.new }

        it 'does not crop' do
          expect(image).not_to receive(:crop)
        end
      end

      context 'when specifing absolute geometry' do
        let(:region) { IIIF::Image::Region::Absolute.new(80, 15, 60, 75) }

        it 'crops to that region' do
          expect(image).to receive(:crop).with(80, 15, 60, 75)
        end
      end

      context 'when specifing percent geometry' do
        let(:region) { IIIF::Image::Region::Percent.new(10, 10, 80, 70) }
        before { allow(image_info).to receive_messages(width: 100, height: 100, format: 'jpeg', channels: channels) }

        it 'crops to that region' do
          expect(image).to receive(:crop).with(10, 10, 80, 70)
        end
      end

      context 'when specifing square geometry' do
        let(:region) { IIIF::Image::Region::Square.new }

        it 'crops a square the size of the shortest edge' do
          expect(image).to receive(:crop).with(62, 0, 376, 376)
        end
      end
    end

    describe 'rotate' do
      after { subject }

      context 'when no rotation (0) is specified' do
        it 'does not rotate' do
          expect(image).not_to receive(:rotate)
        end
      end

      context 'when rotation is specified' do
        let(:rotation) { 45 }

        it 'rotates the image' do
          expect(image).to receive(:rotate).with(45)
        end
      end
    end

    describe 'colourspace' do
      after { subject }

      context 'when quality is default or color' do
        it 'leaves the image in color' do
          expect(image).not_to receive(:colourspace).with(:b_w)
          expect(image).not_to receive(:>)
        end
      end

      context 'when quality is gray' do
        let(:transformation) { IIIF::Image::Transformation.new(region: region, size: size, rotation: rotation, quality: 'gray') }

        it 'makes the image grayscale' do
          expect(image).to receive(:colourspace).with(:b_w)
        end
      end

      context 'when quality is bitonal' do
        let(:transformation) { IIIF::Image::Transformation.new(region: region, size: size, rotation: rotation, quality: 'bitonal') }

        it 'makes the image bitonal' do
          expect(image).to receive(:colourspace).with(:b_w)
          expect(image).to receive(:>).with(200)
        end
      end
    end
  end
end
