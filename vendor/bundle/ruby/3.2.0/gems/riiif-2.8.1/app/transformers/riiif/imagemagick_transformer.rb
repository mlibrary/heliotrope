module Riiif
  # Transforms an image using Imagemagick
  class ImagemagickTransformer < AbstractTransformer
    def command_factory
      ImagemagickCommandFactory
    end
  end
end
