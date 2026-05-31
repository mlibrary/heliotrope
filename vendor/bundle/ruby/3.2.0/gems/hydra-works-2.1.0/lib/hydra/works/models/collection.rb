module Hydra::Works
  class Collection < ActiveFedora::Base
    include Hydra::Works::CollectionBehavior
  end
end
