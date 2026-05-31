module Hydra::Works
  # This module provides all of the Behaviors of a Hydra::Works::Collection
  #
  # behavior:
  #   1) Hydra::Works::Collection can aggregate Hydra::Works::Collection
  #   2) Hydra::Works::Collection can aggregate Hydra::Works::Work

  #   3) Hydra::Works::Collection can NOT aggregate Hydra::PCDM::Collection unless it is also a Hydra::Works::Collection
  #   4) Hydra::Works::Collection can NOT aggregate Hydra::Works::FileSet
  #   5) Hydra::Works::Collection can NOT aggregate non-PCDM object
  #   6) Hydra::Works::Collection can NOT contain Hydra::PCDM::File
  #   7) Hydra::Works::Collection can NOT contain

  #   8) Hydra::Works::Collection can have descriptive metadata
  #   9) Hydra::Works::Collection can have access metadata
  module CollectionBehavior
    extend ActiveSupport::Concern

    included do
      def self.type_validator
        Hydra::PCDM::Validators::CompositeValidator.new(
          super,
          Hydra::Works::NotFileSetValidator
        )
      end
      include Hydra::PCDM::CollectionBehavior

      type [Hydra::PCDM::Vocab::PCDMTerms.Collection, Vocab::WorksTerms.Collection]
    end

    def parent_collections
      in_collections + member_of_collections
    end

    def parent_collection_ids
      in_collection_ids + member_of_collection_ids
    end

    def child_collections
      collections + member_collections
    end

    def child_collection_ids
      collection_ids + member_collection_ids
    end

    def child_works
      works + member_works
    end

    def child_work_ids
      work_ids + member_work_ids
    end

    def ordered_works
      ordered_members.to_a.select(&:work?)
    end

    def ordered_work_ids
      ordered_works.map(&:id)
    end

    def works
      members.select(&:work?)
    end

    def work_ids
      works.map(&:id)
    end

    def member_collections
      return [] if id.nil?
      member_objects = ActiveFedora::Base.where('member_of_collection_ids_ssim' => id)
      member_objects.select(&:collection?).to_a
    end

    def member_collection_ids
      member_collections.map(&:id)
    end

    def member_works
      return [] if id.nil?
      member_objects = ActiveFedora::Base.where('member_of_collection_ids_ssim' => id)
      member_objects.select(&:work?).to_a
    end

    def member_work_ids
      member_works.map(&:id)
    end

    # @return [Boolean] whether this instance is a Hydra::Works Collection.
    def collection?
      true
    end

    # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
    def work?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
    def file_set?
      false
    end
  end
end
