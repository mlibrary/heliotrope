module Hydra::PCDM::Validators
  class PCDMObjectValidator
    def self.validate!(_association, record)
      raise ActiveFedora::AssociationTypeMismatch, "#{record} is not a PCDM object." unless
        record.try(:pcdm_object?)
    end
  end
end
