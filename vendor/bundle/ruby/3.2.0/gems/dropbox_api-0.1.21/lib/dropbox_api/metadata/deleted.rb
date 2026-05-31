# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {Deleted} object:
  #
  # ```json
  # {
  #   ".tag": "deleted",
  #   "name": "file.txt",
  #   "path_lower": "/file.txt",
  #   "path_display": "/file.txt"
  # }
  # ```
  class Deleted < Base
    field :name, String
    field :path_lower, String
    field :path_display, String
  end
end
