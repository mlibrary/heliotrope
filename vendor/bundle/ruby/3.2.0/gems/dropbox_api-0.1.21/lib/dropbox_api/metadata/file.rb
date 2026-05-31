# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {File} object:
  #
  # ```json
  # {
  #   ".tag": "file",
  #   "name": "Prime_Numbers.txt",
  #   "path_lower": "/homework/math/prime_numbers.txt",
  #   "path_display": "/Homework/math/Prime_Numbers.txt",
  #   "id": "id:a4ayc_80_OEAAAAAAAAAXw",
  #   "client_modified": "2015-05-12T15:50:38Z",
  #   "server_modified": "2015-05-12T15:50:38Z",
  #   "rev": "a1c10ce0dd78",
  #   "size": 7212,
  #   "sharing_info": {
  #     "read_only": true,
  #     "parent_shared_folder_id": "84528192421",
  #     "modified_by": "dbid:AAH4f99T0taONIb-OurWxbNQ6ywGRopQngc"
  #   }
  # }
  # ```
  class File < Base
    field :name, String
    field :path_lower, String, :optional
    field :path_display, String, :optional
    field :id, String
    field :client_modified, Time
    field :server_modified, Time
    field :rev, String
    field :size, Integer
    field :content_hash, String, :optional
    field :media_info, DropboxApi::Metadata::MediaInfo, :optional
    field :has_explicit_shared_members, :boolean, :optional

    def to_hash
      super.merge('.tag' => 'file')
    end
  end
end
