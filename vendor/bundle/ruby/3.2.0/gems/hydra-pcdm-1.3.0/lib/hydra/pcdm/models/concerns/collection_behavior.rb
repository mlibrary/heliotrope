module Hydra::PCDM
  ##
  # Implements behavior for PCDM collections.
  #
  # The behavior is summarized as:
  #   1) Hydra::PCDM::Collection can aggregate (pcdm:hasMember)  Hydra::PCDM::Collection (no infinite loop, e.g., A -> B -> C -> A)
  #   2) Hydra::PCDM::Collection can aggregate (pcdm:hasMember)  Hydra::PCDM::Object
  #   3) Hydra::PCDM::Collection can aggregate (ore:aggregates) Hydra::PCDM::Object  (Object related to the Collection)
  #   4) Hydra::PCDM::Collection can NOT aggregate non-PCDM object
  #   5) Hydra::PCDM::Collection can NOT contain (pcdm:hasFile)  Hydra::PCDM::File
  #   6) Hydra::PCDM::Collection can have descriptive metadata
  #   7) Hydra::PCDM::Collection can have access metadata
  #
  module CollectionBehavior
    extend ActiveSupport::Concern

    included do
      type Vocab::PCDMTerms.Collection
      include ::Hydra::PCDM::PcdmBehavior
    end

    ##
    # @see ActiveSupport::Concern
    module ClassMethods
      ##
      # @return [Class] the indexer class
      def indexer
        Hydra::PCDM::CollectionIndexer
      end

      ##
      # @return [Class] the validator class
      def type_validator
        Validators::PCDMCollectionValidator
      end
    end

    ##
    # @return [Enumerable<PCDM::CollectionBehavior>]
    def collections
      members.select(&:pcdm_collection?)
    end

    ##
    # @return [Enumerable<String>]
    def collection_ids
      members.select(&:pcdm_collection?).map(&:id)
    end

    ##
    # @return [Enumerable<PCDM::CollectionBehavior>]
    def ordered_collections
      ordered_members.to_a.select(&:pcdm_collection?)
    end

    ##
    # @return [Enumerable<String>]
    def ordered_collection_ids
      ordered_collections.map(&:id)
    end

    ##
    # @return [Boolean] whether this instance is a PCDM Object.
    def pcdm_object?
      false
    end

    ##
    # @return [Boolean] whether this instance is a PCDM Collection.
    def pcdm_collection?
      true
    end
  end
end
