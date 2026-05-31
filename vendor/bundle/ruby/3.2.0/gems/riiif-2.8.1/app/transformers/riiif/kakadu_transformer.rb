module Riiif
  # Transforms an image using Kakadu
  class KakaduTransformer < AbstractTransformer
    def command_factory
      KakaduCommandFactory
    end

    def transform
      with_tempfile do |file_name|
        execute(command_builder.command(file_name))
        post_process(file_name, command_builder.reduction_factor)
      end
    end

    def with_tempfile
      Tempfile.open(['riiif-intermediate', '.bmp']) do |f|
        yield f.path
      end
    end

    # The data we get back from kdu_expand is a bmp and we need to change it
    # to the requested format by calling Imagemagick.
    def post_process(intermediate_file, reduction_factor)
      # Calculate a new set of transforms with respect to reduction_factor
      transformation = if reduction_factor
                         reduce(without_crop, reduction_factor)
                       else
                         without_crop
                       end
      Riiif::File.new(intermediate_file).extract(transformation, image_info)
    end

    private

      # Create a clone of the Transformation, without the crop
      # @return [IIIF::Image::Transformation] a new transformation
      def without_crop
        IIIF::Image::Transformation.new(region: IIIF::Image::Region::Full.new,
                                        size: transformation.size.dup,
                                        quality: transformation.quality,
                                        rotation: transformation.rotation,
                                        format: transformation.format)
      end

      # Create a clone of this Transformation, scaled by the factor
      # @param [IIIF::Image::Transformation] transformation the transformation to clone
      # @param [Integer] factor the scale for the new transformation
      # @return [Transformation] a new transformation, scaled by factor
      def reduce(transformation, factor)
        resize = Resize.new(transformation.size, image_info)
        IIIF::Image::Transformation.new(region: transformation.region.dup,
                                        size: resize.reduce(factor),
                                        quality: transformation.quality,
                                        rotation: transformation.rotation,
                                        format: transformation.format)
      end

      def tmp_path
        @link_path ||= LinkNameService.create
      end
  end
end
