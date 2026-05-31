# frozen_string_literal: true
module Hydra::Derivatives::Processors
  # Processors take a single input and produce a single output
  class Processor
    attr_accessor :source_path, :directives, :output_file_service

    # @param [String] source_path path to the file on disk
    # @param [Hash] directives directions for creating the output
    # @option [String] :format the format of the output
    # @option [String] :url the location to put the output
    # @param [Hash] opts
    # @option [#call] :output_file_service An output file service to call
    def initialize(source_path, directives, opts = {})
      self.source_path = source_path
      self.directives = directives
      self.output_file_service = opts.fetch(:output_file_service, Hydra::Derivatives.output_file_service)
    end

    def process
      raise "Processor is an abstract class. Implement `process' on #{self.class.name}"
    end

    def output_filename_for(_name)
      File.basename(source_path)
    end

    # @deprecated Please use a PersistOutputFileService class to save an object
    def output_file
      raise NotImplementedError, "Processor is an abstract class. Utilize an implementation of a PersistOutputFileService class in #{self.class.name}"
    end
  end
end
