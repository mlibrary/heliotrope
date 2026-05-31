module Hydra::Works::Characterization
  class ImageSchema < ActiveTriples::Schema
    property :byte_order, predicate: RDF::URI('http://sweet.jpl.nasa.gov/2.2/reprDataFormat.owl#byteOrder')
    property :compression, predicate: RDF::URI('http://projecthydra.org/ns/mix/compressionScheme')
    property :height, predicate: RDF::Vocab::EBUCore.height
    property :width, predicate: RDF::Vocab::EBUCore.width
    property :color_space, predicate: RDF::Vocab::EXIF.colorSpace
    property :profile_name, predicate: RDF::URI('http://projecthydra.org/ns/mix/colorProfileName')
    property :profile_version, predicate: RDF::URI('http://projecthydra.org/ns/mix/colorProfileVersion')
    property :orientation, predicate: RDF::Vocab::EXIF.orientation
    property :color_map, predicate: RDF::URI('http://projecthydra.org/ns/mix/colorMap')
    property :image_producer, predicate: RDF::Vocab::MARCRelators.pht
    property :capture_device, predicate: RDF::Vocab::EXIF.model
    property :scanning_software, predicate: RDF::Vocab::EXIF.software
    # exif_version is in core set of tehcnical metadata
    property :gps_timestamp, predicate: RDF::Vocab::EXIF.gpsTimeStamp
    property :latitude, predicate: RDF::Vocab::EXIF.gpsLatitude
    property :longitude, predicate: RDF::Vocab::EXIF.gpsLongitude
  end
end
