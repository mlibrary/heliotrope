module Hydra::Works
  # This module provides all of the Behaviors of a Hydra::Works::GenericFile
  #
  # behavior:
  #   1) Hydra::Works::FileSet can contain (pcdm:hasFile) Hydra::PCDM::File   (inherits from Hydra::PCDM::Object)
  #   2) Hydra::Works::FileSet can contain (pcdm:hasRelatedFile) Hydra::PCDM::File   (inherits from Hydra::PCDM::Object)
  #   3) Hydra::Works::FileSet can aggregate (pcdm:hasMember) Hydra::Works::FileSet
  #   4) Hydra::Works::FileSet can NOT aggregate anything other than Hydra::Works::FileSets
  #   5) Hydra::Works::FileSet can have descriptive metadata
  #   6) Hydra::Works::FileSet can have access metadata
  module FileSetBehavior
    extend ActiveSupport::Concern

    included do
      def self.type_validator
        Hydra::PCDM::Validators::CompositeValidator.new(
          Hydra::Works::NotCollectionValidator,
          super
        )
      end
      include Hydra::PCDM::ObjectBehavior
      include Hydra::Works::ContainedFiles
      include Hydra::Works::Derivatives
      include Hydra::Works::MimeTypes
      include Hydra::Works::VersionedContent
      before_destroy :remove_from_works

      type [Hydra::PCDM::Vocab::PCDMTerms.Object, Vocab::WorksTerms.FileSet]
    end

    # @return [Boolean] whether this instance is a Hydra::Works Collection.
    def collection?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
    def work?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
    def file_set?
      true
    end

    def parent_works
      in_works + member_of_works
    end

    def parent_work_ids
      in_work_ids + member_of_work_ids
    end

    def in_works
      ordered_by.select { |parent| parent.class.included_modules.include?(Hydra::Works::WorkBehavior) }.to_a
    end

    def in_work_ids
      in_works.map(&:id)
    end

    def member_of_works
      member_of.select(&:work?).to_a
    end

    def member_of_work_ids
      member_of_works.map(&:id)
    end

    private

      def remove_from_works
        in_works.each do |parent|
          parent.ordered_members.delete(self) # Delete the list node
          parent.members.delete(self) # Delete the indirect container Proxy
          parent.save! # record the changes to the ordered members
        end
      end
  end
end
