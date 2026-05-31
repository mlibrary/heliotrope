# frozen_string_literal: true

module DropboxApi::Metadata
  class SearchMatchV2 < Base
    # The metadata for the matched file or folder.
    field :metadata, DropboxApi::Metadata::MetadataV2

    # The type of the match. This field is optional.
    field :match_type, SearchMatchTypeV2

    def resource
      # for some strange reason, v2 of this search endpoint doesn't have
      # the `resource` field anymore and file metadata is wrapped in a
      # metadata/metadata field...
      metadata.metadata
    end
  end
end
