# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Riiif::KakaduCommandFactory do
  subject(:instance) { described_class.new(path, info, transformation) }

  let(:info) { double(:info) }
  let(:path) { 'foo.jp2' }
  let(:region) { IIIF::Image::Region::Full.new }
  let(:size) { IIIF::Image::Size::Full.new }
  let(:quality) { nil }
  let(:rotation) { nil }
  let(:fmt) { nil }

  let(:transformation) do
    IIIF::Image::Transformation.new(region: region,
                                    size: size,
                                    quality: quality,
                                    rotation: rotation,
                                    format: fmt)
  end

  describe '#command' do
    subject { instance.command '/tmp/bar.bmp' }

    context 'with a full size image' do
      it { is_expected.to eq 'kdu_expand -quiet -i foo.jp2 -num_threads 4 -o /tmp/bar.bmp' }
    end
  end

  describe '#region' do
    subject { instance.send(:region) }
    let(:info) { double(height: 300, width: 300) }

    context 'with a full' do
      it { is_expected.to be nil }
    end

    context 'with absolute' do
      let(:region) { IIIF::Image::Region::Absolute.new(25, 75, 150, 100) }
      it { is_expected.to eq ' -region "{0.25,0.08333333333333333},{0.3333333333333333,0.5}"' }
    end

    context 'with a square' do
      let(:region) { IIIF::Image::Region::Square.new }
      it { is_expected.to eq ' -region "{0.0,0},{1.0,1.0}"' }
    end

    context 'with a percentage' do
      let(:region) { IIIF::Image::Region::Percent.new(20.0, 30.0, 40.0, 50.0) }
      it { is_expected.to eq ' -region "{0.3,0.2},{0.5,0.4}"' }
    end
  end

  describe '#reduction_factor' do
    subject { instance.send(:reduction_factor) }

    let(:info) { Riiif::ImageInformation.new(width: 300, height: 300) }

    context 'for a full size image' do
      it { is_expected.to eq nil }
    end

    context 'when the aspect ratio is maintined for absolute' do
      let(:size) { IIIF::Image::Size::Absolute.new(145, 145) }
      it { is_expected.to eq 1 }
    end

    context 'when the aspect ratio is not-maintined' do
      let(:size) { IIIF::Image::Size::Absolute.new(100, 145) }
      it { is_expected.to eq nil }
    end

    context 'when aspect ratio is maintained for 45 pct' do
      let(:size) { IIIF::Image::Size::Percent.new(45.0) }
      it { is_expected.to eq 1 }
    end

    context 'when aspect ratio is maintained for 20 pct' do
      let(:size) { IIIF::Image::Size::Percent.new(20.0) }
      it { is_expected.to eq 2 }
    end
  end
end
