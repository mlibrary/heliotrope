# frozen_string_literal: true

require 'rails_helper'
require 'shellwords'

RSpec.describe Riiif::TifftopnmCommandFactory do
  subject(:factory) { described_class.new(path, image_info, transformation) }

  let(:path) { '/path/to/image.tif' }
  let(:image_info) { Riiif::ImageInformation.new(width: 4000, height: 6000) }

  # Helper to build a transformation from IIIF URL params
  def build_transformation(region: 'full', size: 'full', rotation: '0', quality: 'default', format: 'jpg')
    IIIF::Image::OptionDecoder.decode(region: region, size: size, rotation: rotation,
                                      quality: quality, format: format)
  end

  describe '#command' do
    context 'full region, full size, jpg (no crop, no resize)' do
      let(:transformation) { build_transformation }

      it 'returns tifftopnm | pnmtojpeg pipeline' do
        expect(factory.command).to match(/tifftopnm -byrow #{path}/)
        expect(factory.command).not_to include('pamcut')
        expect(factory.command).not_to include('pnmscalefixed')
        expect(factory.command).to include('pnmtojpeg -quality 95')
      end
    end

    context 'full region, full size, png' do
      let(:transformation) { build_transformation(format: 'png') }

      it 'returns tifftopnm | pnmtopng pipeline' do
        expect(factory.command).to match(/tifftopnm -byrow #{path}/)
        expect(factory.command).not_to include('pamcut')
        expect(factory.command).not_to include('pnmscalefixed')
        expect(factory.command).to include('pnmtopng')
        expect(factory.command).not_to include('pnmtojpeg')
      end
    end

    context 'absolute crop with jpg output' do
      let(:transformation) { build_transformation(region: '2048,4096,1024,1024') }

      it 'includes pamcut with x, y, width, height arguments' do
        expect(factory.command).to match(/tifftopnm -byrow #{path}/)
        expect(factory.command).to include('pamcut 2048 4096 1024 1024')
        expect(factory.command).not_to include('pnmscalefixed')
        expect(factory.command).to include('pnmtojpeg -quality 95')
      end
    end

    context 'absolute crop with png output' do
      let(:transformation) { build_transformation(region: '0,0,512,512', format: 'png') }

      it 'pipes through pamcut and pnmtopng' do
        expect(factory.command).to include('pamcut 0 0 512 512')
        expect(factory.command).to include('pnmtopng')
      end
    end

    context 'width-only size' do
      let(:transformation) { build_transformation(size: '200,') }

      it 'uses -xsize' do
        expect(factory.command).to include('pnmscalefixed -xsize 200')
        expect(factory.command).not_to include('pamcut')
        expect(factory.command).to include('pnmtojpeg -quality 95')
      end
    end

    context 'height-only size' do
      let(:transformation) { build_transformation(size: ',300') }

      it 'uses -ysize' do
        expect(factory.command).to include('pnmscalefixed -ysize 300')
        expect(factory.command).not_to include('pamcut')
      end
    end

    context 'best-fit size (both dimensions)' do
      let(:transformation) { build_transformation(size: '!400,300') }

      it 'uses -xysize with both dimensions' do
        expect(factory.command).to match(/pnmscalefixed -xysize \d+ \d+/)
        expect(factory.command).not_to include('pamcut')
      end
    end

    context 'percent size' do
      let(:transformation) { build_transformation(size: 'pct:50') }

      it 'uses -xysize to scale proportionally' do
        expect(factory.command).to match(/pnmscalefixed -xysize \d+ \d+/)
      end
    end

    context 'crop and size together' do
      let(:transformation) { build_transformation(region: '2048,4096,1024,1024', size: ',200') }

      it 'crops then resizes' do
        cmd = factory.command
        expect(cmd).to include('pamcut 2048 4096 1024 1024')
        expect(cmd).to include('pnmscalefixed -ysize 200')
        # crop should come before resize in the pipeline
        expect(cmd.index('pamcut')).to be < cmd.index('pnmscalefixed')
      end
    end

    context 'square region' do
      let(:transformation) { build_transformation(region: 'square') }

      it 'includes a pamcut for the square crop' do
        expect(factory.command).to include('pamcut')
      end

      it 'crops to the minimum dimension, centered on the long axis' do
        # image_info is 4000x6000 (portrait), so min=4000, offset=(6000-4000)/2=1000
        # expected: pamcut 0 1000 4000 4000
        expect(factory.command).to include('pamcut 0 1000 4000 4000')
      end
    end

    context 'percent region' do
      let(:transformation) { build_transformation(region: 'pct:25,25,50,50') }

      it 'converts percent region to absolute pamcut arguments' do
        # 25% of 4000=1000 offset_x, 25% of 6000=1500 offset_y
        # 50% of 4000=2000 width, 50% of 6000=3000 height
        expect(factory.command).to include('pamcut 1000 1500 2000 3000')
      end
    end

    context 'max size' do
      let(:transformation) { build_transformation(size: 'max') }

      it 'does not add a resize step' do
        expect(factory.command).not_to include('pnmscalefixed')
      end
    end

    context 'path with spaces or shell metacharacters' do
      let(:path) { '/path/to/my image & data.tif' }
      let(:transformation) { build_transformation }

      it 'shell-escapes the path to prevent command injection' do
        cmd = factory.command
        expect(cmd).not_to include('/path/to/my image & data.tif')
        expect(cmd).to include(Shellwords.escape(path))
      end
    end
  end
end
