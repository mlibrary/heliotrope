module Hydra::Works::Characterization
  class BaseSchema < ActiveTriples::Schema
    property :format_label, predicate: RDF::Vocab::PREMIS.hasFormatName
    property :file_size, predicate: RDF::Vocab::EBUCore.fileSize
    property :well_formed, predicate: RDF::URI.new("http://projecthydra.org/ns/fits/wellFormed")
    property :valid, predicate: RDF::URI.new("http://projecthydra.org/ns/fits/valid")
    property :date_created, predicate: RDF::Vocab::EBUCore.dateCreated
    property :fits_version, predicate: RDF::Vocab::PREMIS.hasCreatingApplicationVersion
    property :exif_version, predicate: RDF::Vocab::EXIF.exifVersion
    property :original_checksum, predicate: RDF::Vocab::NFO.hashValue
  end
end
