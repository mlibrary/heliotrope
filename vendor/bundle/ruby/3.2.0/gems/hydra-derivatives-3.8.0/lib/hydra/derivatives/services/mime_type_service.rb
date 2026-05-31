# frozen_string_literal: true
require 'mime/types'

module Hydra::Derivatives
  module MimeTypeService
    # @param [String] file_path path to a file
    def self.mime_type(file_path)
      MIME::Types.type_for(file_path).first.to_s
    end
  end
end
