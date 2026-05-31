# frozen_string_literal: true

module Riiif
  # Builds a command to run a transformation using Kakadu
  class KakaduCommandFactory
    class_attribute :external_command
    self.external_command = 'kdu_expand'

    # A helper method to instantiate and invoke build
    # @param [String] path the location of the file
    # @param info [ImageInformation] information about the source
    # @param [Transformation] transformation
    def initialize(path, info, transformation)
      @path = path
      @info = info
      @transformation = transformation
    end

    attr_reader :path, :info, :transformation

    # @param tmp_file [String] the path to the temporary file
    # @return [String] a command for running kdu_expand to produce the requested output
    def command(tmp_file)
      [external_command, quiet, input, threads, region, reduce, output(tmp_file)].join
    end

    def reduction_factor
      @reduction_factor ||= Resize.new(transformation.size, info).reduction_factor
    end

    private

      def input
        " -i #{path}"
      end

      def output(output_filename)
        " -o #{output_filename}"
      end

      def threads
        ' -num_threads 4'
      end

      def quiet
        ' -quiet'
      end

      def region
        region_arg = Crop.new(transformation.region, info).to_kakadu
        " -region \"#{region_arg}\"" if region_arg
      end

      # kdu_expand is not capable of arbitrary scaling, but it does
      # offer a -reduce argument which is capable of downscaling by
      # factors of 2, significantly speeding decompression. We can
      # use it if either the percent is <=50, or the height/width
      # are <=50% of full size.
      def reduce
        " -reduce #{reduction_factor}" if reduction_factor && reduction_factor != 0
      end
  end
end
