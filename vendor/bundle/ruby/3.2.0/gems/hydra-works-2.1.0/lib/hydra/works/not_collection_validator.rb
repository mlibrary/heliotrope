module Hydra::Works
  class NotCollectionValidator
    def self.validate!(_association, record)
      if record.try(:collection?)
        raise ActiveFedora::AssociationTypeMismatch, "#{record} is a Collection and may not be a member of the association"
      end
    end
  end
end
