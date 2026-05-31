# frozen_string_literal: true

module Riiif
  # Builds a command to run a transformation using Imagemagick
  class ImagemagickCommandFactory
    # perhaps you want to use GraphicsMagick instead, set to "gm convert"
    class_attribute :external_command
    self.external_command = 'convert'

    # A helper method to instantiate and invoke build
    # @param [String] path the location of the file
    # @param info [ImageInformation] information about the source
    # @param [Transformation] transformation
    # @param [Integer] compression (85) the compression level to use (set 0 for no compression)
    # @param [String] sampling_factor ("4:2:0") the chroma sample factor (set 0 for no compression)
    # @param [Boolean] strip_metadata (true) do we want to strip EXIF tags?
    def initialize(path, info, transformation, compression: 85, sampling_factor: '4:2:0', strip_metadata: true)
      @path = path
      @info = info
      @transformation = transformation
      @compression = compression
      @sampling_factor = sampling_factor
      @strip_metadata = strip_metadata
    end

    attr_reader :path, :info, :transformation, :compression, :sampling_factor, :strip_metadata

    # @return [String] a command for running imagemagick to produce the requested output
    def command
      [
        external_command,
        crop,
        size,
        rotation,
        colorspace,
        quality,
        sampling,
        metadata,
        alpha_channel,
        input,
        output
      ].join
    end

    def reduction_factor
      nil
    end

    private

      def use_compression?
        compression > 0 && jpeg?
      end

      def jpeg?
        transformation.format == 'jpg'.freeze
      end

      def alpha_channel?
        info.channels =~ /rgba/i
      end

      def layer_spec
        '[0]' if info.format =~ /pdf/i
      end

      def input
        " '#{path}#{layer_spec}'"
      end

      # In cases where the input file has an alpha_channel but the transformation
      #   format is 'jpg', change to 'png' as jpeg does not support alpha channels
      # pipe the output to STDOUT
      def output
        if alpha_channel? && jpeg?
          " png:-"
        else
          " #{transformation.format}:-"
        end
      end

      def crop
        directive = Crop.new(transformation.region, info).to_imagemagick
        " -crop #{directive}" if directive
      end

      def size
        directive = Resize.new(transformation.size, info).to_imagemagick
        " -resize #{directive}" if directive
      end

      def rotation
        return if transformation.rotation.zero?
        " -virtual-pixel white +distort srt #{transformation.rotation}"
      end

      def quality
        " -quality #{compression}" if use_compression?
      end

      def metadata
        ' -strip' if strip_metadata
      end

      def sampling
        " -sampling-factor #{sampling_factor}" if jpeg? && !alpha_channel?
      end

      def alpha_channel
        if info.format =~ /pdf/i
          ' -alpha remove'
        elsif alpha_channel?
          ' -alpha on'
        end
      end

      def colorspace
        case transformation.quality
        when 'grey'
          ' -colorspace Gray'
        when 'bitonal'
          ' -colorspace Gray -type Bilevel'
        end
      end
  end
end
