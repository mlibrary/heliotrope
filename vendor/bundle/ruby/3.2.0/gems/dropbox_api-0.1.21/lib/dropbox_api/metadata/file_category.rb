# frozen_string_literal: true

module DropboxApi::Metadata
  class FileCategory < DropboxApi::Metadata::Tag
    VALID_VALUES = %i[
      image
      document
      pdf
      spreadsheet
      presentation
      audio
      video
      folder
      paper
      others
    ].freeze

    def self.valid_values
      VALID_VALUES
    end
  end
end
