# frozen_string_literal: true
require 'mini_magick'

module Hydra::Derivatives::Processors
  class Image < Processor
    class_attribute :timeout

    def process
      timeout ? process_with_timeout : create_resized_image
    end

    def process_with_timeout
      Timeout.timeout(timeout) { create_resized_image }
    rescue Timeout::Error
      raise Hydra::Derivatives::TimeoutError, "Unable to process image derivative\nThe command took longer than #{timeout} seconds to execute"
    end

    protected

      # When resizing images, it is necessary to flatten any layers, otherwise the background
      # may be completely black. This happens especially with PDFs. See #110
      def create_resized_image
        create_image do |xfrm|
          if size
            xfrm.combine_options do |i|
              i.flatten
              i.resize(size)
            end
          end
        end
      end

      def create_image
        xfrm = selected_layers(load_image_transformer)
        yield(xfrm) if block_given?
        xfrm.format(directives.fetch(:format))
        xfrm.quality(quality.to_s) if quality
        write_image(xfrm)
      end

      def write_image(xfrm)
        output_io = StringIO.new
        xfrm.write(output_io)
        output_io.rewind
        output_file_service.call(output_io, directives)
      end

      # Override this method if you want a different transformer, or need to load the
      # raw image from a different source (e.g. external file)
      def load_image_transformer
        MiniMagick::Image.open(source_path)
      end

    private

      def size
        directives.fetch(:size, nil)
      end

      def quality
        directives.fetch(:quality, nil)
      end

      def selected_layers(image)
        if /pdf/i.match?(image.type)
          image.layers[directives.fetch(:layer, 0)]
        elsif directives.fetch(:layer, false)
          image.layers[directives.fetch(:layer)]
        else
          image
        end
      end
  end
end
