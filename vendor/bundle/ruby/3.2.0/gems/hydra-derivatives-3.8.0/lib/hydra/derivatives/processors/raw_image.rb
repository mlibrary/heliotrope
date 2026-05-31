# frozen_string_literal: true
require 'mini_magick'

module Hydra::Derivatives::Processors
  class RawImage < Image
    class_attribute :timeout

    protected

      def create_image(destination_name, format, quality = nil)
        xfrm = load_image_transformer
        # Transpose format and scaling due to the fact that ImageMagick can
        # read but not write RAW files and this will otherwise cause many
        # cryptic segmentation faults
        xfrm.format(format)
        yield(xfrm) if block_given?
        xfrm.quality(quality.to_s) if quality
        write_image(destination_name, format, xfrm)
        remove_temp_files(xfrm)
      end

      # Delete any temp files that might clutter up the disk if
      # you are doing a batch or don't touch your temporary storage
      # for a long time
      def remove_temp_files(xfrm)
        xfrm.destroy!
      end

      # Override this method if you want a different transformer, or # need to load the raw image from a different source (e.g.
      # external file).
      #
      # In this case always add an extension to help out MiniMagick
      # with RAW files
      def load_image_transformer
        MiniMagick::Image.open(source_path)
      end
  end
end
