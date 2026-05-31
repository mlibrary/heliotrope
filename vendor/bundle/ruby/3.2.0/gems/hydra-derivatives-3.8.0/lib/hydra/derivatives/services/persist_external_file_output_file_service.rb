# frozen_string_literal: true
require 'addressable'

module Hydra::Derivatives
  class PersistExternalFileOutputFileService < PersistOutputFileService
    # Persists a new file at specified location that points to external content
    # @param [Hash] output information about the external derivative file
    # @option output [String] url the location of the external content
    # @param [Hash] directives directions which can be used to determine where to persist to.
    # @option directives [String] url This can determine the path of the object.
    def self.call(output, directives)
      external_file = ActiveFedora::File.new(directives[:url])
      # TODO: Replace the following two lines with the shorter call to #external_url once active_fedora/pull/1234 is merged
      external_file.content = ''
      external_file.mime_type = "message/external-body; access-type=URL; URL=\"#{output[:url]}\""
      # external_file.external_url = output[:url]
      external_file.original_name = Addressable::URI.parse(output[:url]).path.split('/').last
      external_file.save
    end
  end
end
