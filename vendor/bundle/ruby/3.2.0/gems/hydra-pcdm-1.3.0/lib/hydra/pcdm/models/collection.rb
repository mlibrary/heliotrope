module Hydra::PCDM
  ##
  # A generic implementation of `PCDM::Collection`.
  #
  # @example creating a generic collection
  #   my_collection = Collection.create
  #
  #   my_collection.pcdm_collection? # => true
  #
  class Collection < ActiveFedora::Base
    include Hydra::PCDM::CollectionBehavior
  end
end
