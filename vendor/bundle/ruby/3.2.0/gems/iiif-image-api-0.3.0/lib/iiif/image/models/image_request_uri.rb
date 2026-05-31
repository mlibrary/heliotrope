module IIIF::Image
  # Class to represent IIIF Image Request URI
  class ImageRequestUri < IIIF::Image::URI
    # @param base_uri [String]
    # @param identifier [String]
    # @param transformation [Transformation]
    def initialize(base_uri:, identifier:, transformation:)
      @base_uri = base_uri
      @identifier = identifier
      @transformation = transformation
    end

    def to_s
      "#{base_uri}#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
    end

    delegate :valid?, to: :transformation

    # I think this is unnecessary in later versions https://github.com/bbatsov/rubocop/pull/3883
    # rubocop:disable Lint/UselessAccessModifier
    private

    delegate :region, :size, :rotation, :quality, :format, to: :transformation
  end
end
