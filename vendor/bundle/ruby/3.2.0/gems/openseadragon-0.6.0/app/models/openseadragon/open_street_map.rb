module Openseadragon
  class OpenStreetMap
    def initialize(attributes = {})
    end
    
    def to_tilesource
      {
        type: 'openstreetmaps'
      }
    end
  end
end
