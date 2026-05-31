# frozen_string_literal: true
module Hydra::Derivatives
  class RetrieveSourceFileService
    # Retrieves the source
    # @param [ActiveFedora::Base] object the source file is attached to
    # @param [Hash] options
    # @option options [Symbol] :source a method that can be called on the object to retrieve the source file
    # @yield [Tempfile] a temporary source file that has a lifetime of the block
    def self.call(object, options, &block)
      source_name = options.fetch(:source)
      Hydra::Derivatives::TempfileService.create(object.send(source_name), &block)
    end
  end
end
