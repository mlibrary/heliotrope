# frozen_string_literal: true
module DropboxApi::Metadata
  class Location < Base
    field :latitude, Float
    field :longitude, Float
  end
end
