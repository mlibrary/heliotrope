module Hydra::PCDM
  class File < ActiveFedora::File
    include ActiveFedora::WithMetadata

    metadata do
      configure type: Vocab::PCDMTerms.File
    end
  end
end
