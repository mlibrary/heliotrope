# frozen_string_literal: true
# For the case where the source file is a remote file, and we
# don't want to download the file locally, just return the
# file name or file path (or whatever we need to pass to the
# encoding service so that it can find the file).

module Hydra::Derivatives
  class RemoteSourceFile
    # Finds the file name of the remote source file.
    # @param [String, ActiveFedora::Base] object file name, or an object that has a method that will return the file name
    # @param [Hash] options
    # @option options [Symbol] :source a method that can be called on the object to retrieve the source file's name
    # @yield [String] the file name
    def self.call(object, options, &_block)
      source_name = options.fetch(:source, :to_s)
      yield(object.send(source_name))
    end
  end
end
