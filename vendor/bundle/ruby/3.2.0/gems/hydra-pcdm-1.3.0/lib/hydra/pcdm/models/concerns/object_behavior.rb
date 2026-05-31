module Hydra::PCDM
  ##
  # Implements behavior for PCDM objects.
  #
  # The behavior is summarized as:
  #   1) Hydra::PCDM::Object can aggregate (pcdm:hasMember) Hydra::PCDM::Object
  #   2) Hydra::PCDM::Object can aggregate (ore:aggregates) Hydra::PCDM::Object  (Object related to the Object)
  #   3) Hydra::PCDM::Object can contain (pcdm:hasFile) Hydra::PCDM::File
  #   4) Hydra::PCDM::Object can contain (pcdm:hasRelatedFile) Hydra::PCDM::File
  #   5) Hydra::PCDM::Object can NOT aggregate Hydra::PCDM::Collection
  #   6) Hydra::PCDM::Object can NOT aggregate non-PCDM object
  #   7) Hydra::PCDM::Object can have descriptive metadata
  #   8) Hydra::PCDM::Object can have access metadata
  #
  # @example defining an object class and creating an object
  #   class Book < ActiveFedora::Base
  #     include Hydra::PCDM::ObjectBehavior
  #   end
  #
  #   my_book = Book.create
  #   # #<Book id: "71/3f/07/e0/713f07e0-9d5c-493a-bdb9-7fbfe2160028", head: [], tail: []>
  #
  #   my_book.pcdm_object?     # => true
  #   my_book.pcdm_collection? # => false
  #
  # @example adding a members to an object
  #   class Page < ActiveFedora::Base
  #     include Hydra::PCDM::ObjectBehavior
  #   end
  #
  #   my_book = Book.create
  #   a_page  = Page.create
  #
  #   my_book.members << a_page
  #   my_book.members # => [a_page]
  #
  # @see PcdmBehavior for details about the base behavior required by
  #   this module.
  module ObjectBehavior
    extend ActiveSupport::Concern

    included do
      type Vocab::PCDMTerms.Object
      include ::Hydra::PCDM::PcdmBehavior

      ##
      # @macro [new] directly_contains
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      directly_contains :files, has_member_relation: Vocab::PCDMTerms.hasFile,
                                class_name: 'Hydra::PCDM::File'
    end

    ##
    # @see ActiveSupport::Concern
    module ClassMethods
      ##
      # @return [Class] the indexer class
      def indexer
        Hydra::PCDM::ObjectIndexer
      end

      ##
      # @return [Class] the validator class
      def type_validator
        Validators::PCDMObjectValidator
      end
    end

    ##
    # @return [Boolean] whether this instance is a PCDM Object.
    def pcdm_object?
      true
    end

    ##
    # @return [Boolean] whether this instance is a PCDM Collection.
    def pcdm_collection?
      false
    end

    ##
    # @return [Enumerable<Hydra::PCDM::ObjectBehavior>]
    def in_objects
      member_of.select(&:pcdm_object?).to_a
    end

    ##
    # Gives directly contained files that have the requested RDF Type
    #
    # @param [RDF::URI] uri for the desired Type
    # @return [Enumerable<ActiveFedora::File>]
    #
    # @example
    #   filter_files_by_type(::RDF::URI("http://pcdm.org/ExtractedText"))
    def filter_files_by_type(uri)
      files.reject do |file|
        !file.metadata_node.type.include?(uri)
      end
    end

    ##
    # Finds or Initializes directly contained file with the requested RDF Type
    #
    # @param [RDF::URI] uri for the desired Type
    # @return [ActiveFedora::File]
    #
    # @example
    #   file_of_type(::RDF::URI("http://pcdm.org/ExtractedText"))
    def file_of_type(uri)
      matching_files = filter_files_by_type(uri)
      return matching_files.first unless matching_files.empty?
      Hydra::PCDM::AddTypeToFile.call(files.build, uri)
    end
  end
end
