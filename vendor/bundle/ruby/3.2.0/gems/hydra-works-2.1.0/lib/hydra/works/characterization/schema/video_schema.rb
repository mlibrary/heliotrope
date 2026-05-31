module Hydra::Works::Characterization
  class VideoSchema < ActiveTriples::Schema
    property :height, predicate: RDF::Vocab::EBUCore.height
    property :width, predicate: RDF::Vocab::EBUCore.width
    property :frame_rate, predicate: RDF::Vocab::NFO.frameRate
    property :bit_rate, predicate: RDF::Vocab::EBUCore.bitRate
    property :duration, predicate: RDF::Vocab::NFO.duration
    property :sample_rate, predicate: RDF::Vocab::EBUCore.sampleRate
    property :aspect_ratio, predicate: RDF::Vocab::EBUCore.aspectRatio
  end
end
