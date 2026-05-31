# frozen_string_literal: true

module DropboxApi::Metadata
  class SearchOrderBy < DropboxApi::Metadata::Tag
    VALID_VALUES = %i[
      relevance
      last_modified_time
    ].freeze

    def self.valid_values
      VALID_VALUES
    end
  end
end
