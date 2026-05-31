module Hydra::PCDM
  module Validators
    autoload :AncestorValidator,                 'hydra/pcdm/validators/ancestor_validator'
    autoload :PCDMValidator,                     'hydra/pcdm/validators/pcdm_validator'
    autoload :CompositeValidator,                'hydra/pcdm/validators/composite_validator'
    autoload :PCDMCollectionValidator,           'hydra/pcdm/validators/pcdm_collection_validator'
    autoload :PCDMObjectValidator,               'hydra/pcdm/validators/pcdm_object_validator'
  end
end
