module Hydra::PCDM::Validators
  class PCDMValidator
    def self.validate!(_reflection, record)
      raise ActiveFedora::AssociationTypeMismatch, "#{record} is not a PCDM object or collection." if
        !record.try(:pcdm_object?) && !record.try(:pcdm_collection?)
    end
  end
end
