module Riiif
  class AbstractInfoExtractor
    # A basic image info extractor class from which ImageMagickInfoExtractor and
    # VipsInfoExtractor inherit

    class_attribute :external_command

    def initialize(path)
      @path = path
    end
  end
end
