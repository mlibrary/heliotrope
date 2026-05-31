module Riiif
  class File
    attr_reader :path

    class_attribute :info_extractor_class
    # TODO: add alternative that uses kdu_jp2info

    def self.info_extractor_class
      if Riiif.use_vips?
        VipsInfoExtractor
      else
        ImageMagickInfoExtractor
      end
    end

    # @param input_path [String] The location of an image file
    def initialize(input_path, tempfile = nil)
      @path = input_path
      @tempfile = tempfile # ensures that the tempfile will stick around until this file is garbage collected.
    end

    # @param [Transformation] transformation
    # @param [ImageInformation] image_info
    # @return [String] the processed image data
    def extract(transformation, image_info = info)
      transformer.transform(path, image_info, transformation)
    end

    def transformer
      if Riiif.use_vips?
        VipsTransformer
      elsif Riiif.kakadu_enabled? && path.ends_with?('.jp2')
        KakaduTransformer
      else
        ImagemagickTransformer
      end
    end

    def info
      @info ||= info_extractor.extract
    end

    def info_extractor
      @info_extractor ||= info_extractor_class.new(path)
    end
  end
end
