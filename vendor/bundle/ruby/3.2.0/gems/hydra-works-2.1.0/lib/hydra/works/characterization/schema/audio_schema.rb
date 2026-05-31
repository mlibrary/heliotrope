module Hydra::Works::Characterization
  class AudioSchema < ActiveTriples::Schema
    property :bit_depth, predicate: RDF::Vocab::NFO.bitDepth
    property :channels, predicate: RDF::Vocab::NFO.channels
    property :data_format, predicate: RDF::Vocab::EBUCore.hasDataFormat
    property :frame_rate, predicate: RDF::Vocab::NFO.frameRate
    # bit_rate might be an array containing multiple values
    property :bit_rate, predicate: RDF::Vocab::EBUCore.bitRate
    property :duration, predicate: RDF::Vocab::NFO.duration
    property :sample_rate, predicate: RDF::Vocab::EBUCore.sampleRate
    # properties without cannonical URIs
    property :offset, predicate: RDF::URI('http://projecthydra.org/ns/audio/offset')
  end
end
