# frozen_string_literal: true

module IIIF::Image
  # A data object that describes the IIIF request
  class Transformation
    def initialize(region:, size:, rotation: '0', quality: 'default', format: 'jpg')
      @region = region
      @size = size
      @rotation = rotation
      @quality = quality
      @format = format
    end

    attr_reader :region, :size, :rotation, :quality, :format

    def to_params
      { region: region,
        size: size,
        rotation: rotation,
        quality: quality,
        format: format }
    end

    def valid?
      %w(color gray bitonal default).include? quality
    end

    def ==(other)
      other.class == self.class &&
        other.region == region &&
        other.size == size &&
        other.rotation == rotation &&
        other.quality == quality &&
        other.format == format
    end
  end
end
