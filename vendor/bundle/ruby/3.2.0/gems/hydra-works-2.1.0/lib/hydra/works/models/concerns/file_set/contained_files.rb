module Hydra::Works::ContainedFiles
  extend ActiveSupport::Concern

  # HydraWorks supports only one each of original_file, thumbnail, and extracted_text. However
  # you are free to add an unlimited number of additional types such as different resolutions
  # of images, different derivatives, etc, and use any established vocabulary you choose.

  # TODO: se PCDM vocab class when projecthydra-labs/hydra-pcdm#80 is merged
  included do
    directly_contains_one :original_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#OriginalFile'), class_name: 'Hydra::PCDM::File'
    directly_contains_one :thumbnail, through: :files, type: ::RDF::URI('http://pcdm.org/use#ThumbnailImage'), class_name: 'Hydra::PCDM::File'
    directly_contains_one :extracted_text, through: :files, type: ::RDF::URI('http://pcdm.org/use#ExtractedText'), class_name: 'Hydra::PCDM::File'
  end
end
