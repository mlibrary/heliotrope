# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Riiif::TifftopnmTransformer do
  describe '.transform' do
    let(:path) { File.join(fixture_path, 'kitty.tif') }
    let(:image_info) { Riiif::ImageInformation.new(width: 100, height: 100) }
    let(:transformation) do
      IIIF::Image::OptionDecoder.decode(region: 'full', size: 'full', rotation: '0',
                                        quality: 'default', format: 'jpg')
    end

    it 'returns binary image data without raising' do
      result = described_class.transform(path, image_info, transformation)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end
  end
end
