# frozen_string_literal: true

require 'rails_helper'

# Riiif::File is overridden in app/overrides/riiif/file_overrides.rb to use
# netpbm's tifftopnm for TIFF images. See #400
describe Riiif::File do
  subject { described_class.new(path) }

  let(:path) { File.join(fixture_path, 'kitty.tif') }

  describe '#transformer' do
    context 'when tifftopnm is available and the image is a tiff' do
      before do
        allow(subject).to receive(:tifftopnm_available?).and_return(true)
      end

      it 'returns TifftopnmTransformer' do
        expect(subject.transformer).to eq(Riiif::TifftopnmTransformer)
      end
    end

    context 'when tifftopnm is not available and the image is a tiff' do
      before do
        allow(subject).to receive(:tifftopnm_available?).and_return(false)
      end

      it 'falls back to ImagemagickTransformer' do
        expect(subject.transformer).to eq(Riiif::ImagemagickTransformer)
      end
    end

    context 'when tifftopnm is available but the image is a jpeg' do
      let(:path) { File.join(fixture_path, 'moby-dick.jpg') }

      before do
        allow(subject).to receive(:tifftopnm_available?).and_return(true)
      end

      it 'uses ImagemagickTransformer' do
        expect(subject.transformer).to eq(Riiif::ImagemagickTransformer)
      end
    end
  end
end
