# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {AccessLevel} object:
  #
  # ```json
  # {
  #   ".tag": "viewer"
  # }
  # ```
  class AccessLevel < DropboxApi::Metadata::Tag
    VALID_ACCESS_LEVELS = [
      :owner,
      :editor,
      :viewer,
      :viewer_no_comment
    ]

    def self.valid_values
      VALID_ACCESS_LEVELS
    end
  end
end
