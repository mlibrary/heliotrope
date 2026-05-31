module IIIF::Image
  # Represents a URI to a IIIF image endpoint
  class URI
    # @param base_uri [String]
    # @param identifier [String]
    # @param transformation [Transformation]
    def initialize(base_uri:, identifier:, transformation: nil)
      @base_uri = base_uri
      @identifier = identifier
      @transformation = transformation
    end

    attr_reader :base_uri, :transformation, :identifier

    def to_s
      return to_image_request_uri.to_s if transformation
      base_uri + identifier + '/info.json'
    end

    def valid?
      return true unless transformation
      to_image_request_uri.valid?
    end

    private

    def to_image_request_uri
      ImageRequestUri.new(base_uri: base_uri, identifier: identifier, transformation: transformation)
    end
  end
end
