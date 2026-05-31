# frozen_string_literal: true

module DropboxApi::Metadata
  class MetadataV2 < Base
    field :metadata, DropboxApi::Metadata::Resource
  end
end
