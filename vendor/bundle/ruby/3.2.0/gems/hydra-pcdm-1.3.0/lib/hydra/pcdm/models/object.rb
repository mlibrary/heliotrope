module Hydra::PCDM
  ##
  # A generic implementation of `PCDM::ObjectBehavior`.
  #
  # @example creating a generic object
  #   my_object = Object.create
  #
  #   my_object.pcdm_object? # => true
  #
  class Object < ActiveFedora::Base
    include Hydra::PCDM::ObjectBehavior
  end
end
