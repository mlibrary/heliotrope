# frozen_string_literal: true

Object.send(:remove_const, :RiiifFileOverrides) if Object.const_defined?(:RiiifFileOverrides, false)

RiiifFileOverrides = Module.new do
  # Override transformer selection to use tifftopnm for TIFF images when
  # the netpbm tifftopnm tool is available. tifftopnm is significantly faster
  # than ImageMagick for large TIFFs because it streams row-by-row (-byrow)
  # without loading the entire image into memory.
  def transformer
    if tiff? && tifftopnm_available?
      Riiif::TifftopnmTransformer
    else
      super
    end
  end

  private

    def tiff?
      path.end_with?('.tif', '.tiff') ||
        `file --brief --mime-type #{path.shellescape}`.chomp.include?('tiff')
    end

    def tifftopnm_available?
      system('which tifftopnm > /dev/null 2>&1')
    end
end

Riiif::File.class_eval do
  prepend(RiiifFileOverrides) unless ancestors.include?(RiiifFileOverrides)
end
