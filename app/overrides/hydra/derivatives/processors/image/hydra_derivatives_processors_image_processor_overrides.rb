# frozen_string_literal: true

Hydra::Derivatives::Processors::Image.class_eval do
  prepend(HeliotropeImageProcessorOverrides = Module.new do
    protected

      # Use MiniMagick::Image.new instead of .open to avoid creating an intermediate
      # tempfile copy. This eliminates a race condition where ImageMagick/Ghostscript
      # intermediate files can disappear before delegate processing completes.
      def load_image_transformer
        MiniMagick::Image.new(source_path.to_s)
      end
  end)
end
