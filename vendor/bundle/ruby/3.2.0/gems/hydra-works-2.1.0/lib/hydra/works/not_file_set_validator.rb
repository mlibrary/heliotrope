module Hydra::Works
  class NotFileSetValidator
    def self.validate!(_association, record)
      if record.try(:file_set?)
        raise ActiveFedora::AssociationTypeMismatch, "#{record} is a FileSet and may not be a member of the association"
      end
    end
  end
end
