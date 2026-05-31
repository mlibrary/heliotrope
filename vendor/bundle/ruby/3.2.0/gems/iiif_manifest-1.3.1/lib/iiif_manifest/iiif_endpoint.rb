module IIIFManifest
  class IIIFEndpoint
    attr_reader :url, :profile
    def initialize(url, profile: nil)
      @url = url
      @profile = profile
    end

    def context
      'http://iiif.io/api/image/2/context.json'
    end
  end
end
