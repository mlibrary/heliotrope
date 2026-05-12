# frozen_string_literal: true

# This is a riiif gem monkeypatch to add a new transformer that uses the tifftopnm command instead of ImageMagick for TIFF images.

module Riiif
  # Transforms TIFF images using the netpbm tifftopnm tool instead of ImageMagick.
  # tifftopnm is significantly faster for large TIFFs because it reads row-by-row
  # without loading the entire image into memory first.
  class TifftopnmTransformer < AbstractTransformer
    def command_factory
      TifftopnmCommandFactory
    end
  end
end
