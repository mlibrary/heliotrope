module Hydra
  module PCDM
    # A container for configuration options (note configuration is not yet determined).
    module Config
      INDEXING_MEMBER_IDS_KEY = 'member_ids_ssim'.freeze
      def self.indexing_member_ids_key
        INDEXING_MEMBER_IDS_KEY
      end

      INDEXING_MEMBER_OF_COLLECTION_IDS_KEY = 'member_of_collection_ids_ssim'.freeze
      def self.indexing_member_of_collection_ids_key
        INDEXING_MEMBER_OF_COLLECTION_IDS_KEY
      end

      INDEXING_COLLECTION_IDS_KEY = 'collection_ids_ssim'.freeze
      def self.indexing_collection_ids_key
        INDEXING_COLLECTION_IDS_KEY
      end

      INDEXING_OBJECT_IDS_KEY = 'object_ids_ssim'.freeze
      def self.indexing_object_ids_key
        INDEXING_OBJECT_IDS_KEY
      end
    end
  end
end
