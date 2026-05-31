module Hydra::Works
  # Typically used for very generic applications that don't differentiate
  # between specific content types. If you want a specific type of work
  # extend ActiveFedora::Base and include the following:
  #   include Hydra::Works::WorkBehavior
  class Work < ActiveFedora::Base
    include Hydra::Works::WorkBehavior
  end
end
