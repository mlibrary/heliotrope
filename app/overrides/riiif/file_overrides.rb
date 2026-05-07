# frozen_string_literal: true

Riiif::File.class_eval do
  prepend(Module.new do
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
        return @tiff if defined?(@tiff)
        @tiff = path.end_with?('.tif', '.tiff') ||
          `file --brief --mime-type #{path.shellescape}`.chomp.include?('tiff')
      end

      def tifftopnm_available?
        unless self.class.instance_variable_defined?(:@tifftopnm_available)
          self.class.instance_variable_set(:@tifftopnm_available, system('which tifftopnm > /dev/null 2>&1'))
        end
        self.class.instance_variable_get(:@tifftopnm_available)
      end
  end)
end
