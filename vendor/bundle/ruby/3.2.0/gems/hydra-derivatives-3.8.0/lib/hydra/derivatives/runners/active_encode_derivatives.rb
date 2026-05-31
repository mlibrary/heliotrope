# frozen_string_literal: true
module Hydra::Derivatives
  class ActiveEncodeDerivatives < Runner
    # @param [String, ActiveFedora::Base] object_or_filename source file name (or path), or an object that has a method that will return the file name
    # @param [Hash] options options to pass to the encoder
    # @option options [Symbol] :source a method that can be called on the object to retrieve the source file's name
    # @option options [Symbol] :encode_class class name of the encode object (usually a subclass of ::ActiveEncode::Base)
    # @options options [Array] :outputs a list of desired outputs
    def self.create(object_or_filename, options)
      processor_opts = processor_options(options)
      source_file(object_or_filename, options) do |file_name|
        transform_directives(options.delete(:outputs)).each do |instructions|
          processor = processor_class.new(file_name, instructions, processor_opts)
          processor.process
        end
      end
    end

    # Use the source service configured for this class or default to the remote file service
    def self.source_file_service
      @source_file_service || RemoteSourceFile
    end

    # Use the output service configured for this class or default to the external file service
    def self.output_file_service
      @output_file_service || PersistExternalFileOutputFileService
    end

    def self.processor_class
      Processors::ActiveEncode
    end

    class << self
      private

        # Build an options hash specifically for the processor isolated from the runner options
        def processor_options(options)
          opts = { output_file_service: output_file_service }
          encode_class = options.delete(:encode_class)
          opts = opts.merge(encode_class: encode_class) if encode_class
          opts
        end
    end
  end
end
