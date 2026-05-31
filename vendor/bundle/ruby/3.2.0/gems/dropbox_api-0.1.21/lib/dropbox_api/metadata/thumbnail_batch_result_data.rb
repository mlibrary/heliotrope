# frozen_string_literal: true
module DropboxApi::Metadata
  class ThumbnailBatchResultData < Base
    field :metadata, DropboxApi::Metadata::File
    field :thumbnail, String
  end
end
