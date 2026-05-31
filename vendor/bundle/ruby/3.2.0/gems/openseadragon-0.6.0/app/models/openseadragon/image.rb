module Openseadragon
  class Image
    attr_accessor :id, :width, :height

    class_attribute :file_resolver
   
    class << self
      def find(id)
        file_resolver.find(id)
      end
    end

    def initialize(attributes = {})
      self.id = attributes[:id]
      self.width = attributes[:width]
      self.height = attributes[:height]
    end
    
    def to_tilesource
      {
        identifier: id,
        width: width,
        height: height,
        scale_factors: [1, 2, 3, 4, 5],
        formats: [:jpg, :png],
        qualities: [:native, :bitonal, :grey, :color],
        profile: "http://library.stanford.edu/iiif/image-api/compliance.html#level3",
        tile_width: 1024,
        tile_height: 1024,
        image_host: '/image-service',
      }
    end
  end
end
