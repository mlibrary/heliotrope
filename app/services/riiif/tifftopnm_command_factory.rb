# frozen_string_literal: true

module Riiif
  # Builds a netpbm pipeline command for TIFF images.
  #
  # The pipeline is: tifftopnm | [pamcut] | [pnmscalefixed] | pnmtojpeg/pnmtopng
  #
  # This is faster than ImageMagick for large TIFFs because tifftopnm reads
  # row-by-row (-byrow) without loading the entire image into memory.
  class TifftopnmCommandFactory
    # @param path [String] the location of the TIFF file
    # @param image_info [ImageInformation] information about the source image
    # @param transformation [Transformation] the requested IIIF transformation
    def initialize(path, image_info, transformation)
      @path = path
      @image_info = image_info
      @transformation = transformation
    end

    attr_reader :path, :image_info, :transformation

    # @return [String] a shell pipeline command producing the requested output
    def command
      pipeline = ["tifftopnm -byrow #{path.shellescape}"]
      pipeline << crop_command if crop_command
      pipeline << resize_command if resize_command
      pipeline << encode_command
      pipeline.join(' | ')
    end

    private

      def crop_command
        return @crop_command if defined?(@crop_command)
        @crop_command = build_crop_command
      end

      def resize_command
        return @resize_command if defined?(@resize_command)
        @resize_command = build_resize_command
      end

      def build_crop_command
        region = transformation.region
        return nil if region.is_a?(IIIF::Image::Region::Full)

        if region.is_a?(IIIF::Image::Region::Absolute)
          "pamcut #{region.offset_x} #{region.offset_y} #{region.width} #{region.height}"
        elsif region.is_a?(IIIF::Image::Region::Percent)
          x = (image_info.width * region.x_pct / 100.0).round
          y = (image_info.height * region.y_pct / 100.0).round
          w = (image_info.width * region.width_pct / 100.0).round
          h = (image_info.height * region.height_pct / 100.0).round
          "pamcut #{x} #{y} #{w} #{h}"
        elsif region.is_a?(IIIF::Image::Region::Square)
          min = [image_info.width, image_info.height].min
          max = [image_info.width, image_info.height].max
          offset = (max - min) / 2
          if image_info.height >= image_info.width
            "pamcut 0 #{offset} #{min} #{min}"
          else
            "pamcut #{offset} 0 #{min} #{min}"
          end
        end
      end

      def build_resize_command
        size = transformation.size
        return nil if size.is_a?(IIIF::Image::Size::Full) || size.is_a?(IIIF::Image::Size::Max)

        if size.is_a?(IIIF::Image::Size::Width)
          "pnmscalefixed -xsize #{size.width}"
        elsif size.is_a?(IIIF::Image::Size::Height)
          "pnmscalefixed -ysize #{size.height}"
        elsif size.is_a?(IIIF::Image::Size::Percent)
          resize = Resize.new(size, image_info)
          "pnmscalefixed -xysize #{resize.width.round} #{resize.height.round}"
        else
          # Absolute, BestFit
          "pnmscalefixed -xysize #{size.width} #{size.height}"
        end
      end

      def encode_command
        transformation.format == 'png' ? 'pnmtopng' : 'pnmtojpeg -quality 95'
      end
  end
end
