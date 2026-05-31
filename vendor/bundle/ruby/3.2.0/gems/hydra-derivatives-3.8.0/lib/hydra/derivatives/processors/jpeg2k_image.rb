# frozen_string_literal: true
require 'mini_magick'
require 'nokogiri'

module Hydra::Derivatives::Processors
  class Jpeg2kImage < Processor
    include ShellBasedProcessor

    class << self
      def srgb_profile_path
        File.join [
          File.expand_path('../../../../', __FILE__),
          'color_profiles',
          'sRGB_IEC61966-2-1_no_black_scaling.icc'
        ]
      end

      def kdu_compress_recipe(args, quality, long_dim)
        if args[:recipe].is_a? Symbol
          recipe = [args[:recipe].to_s, quality].join('_').to_sym
          return Hydra::Derivatives.kdu_compress_recipes[recipe] if Hydra::Derivatives.kdu_compress_recipes.key? recipe
          ActiveFedora::Base.logger.warn "No JP2 recipe for :#{args[:recipe]} ('#{recipe}') found in configuration. Using best guess."
          calculate_recipe(args, quality, long_dim)
        elsif args[:recipe].is_a? String
          args[:recipe]
        else
          calculate_recipe(args, quality, long_dim)
        end
      end

      def calculate_recipe(args, quality, long_dim)
        levels_arg = args.fetch(:levels, level_count_for_size(long_dim))
        rates_arg = layer_rates(args.fetch(:layers, 8), args.fetch(:compression, 10))
        tile_size = args.fetch(:tile_size, 1024)
        tiles_arg = "#{tile_size},#{tile_size}"
        jp2_space_arg = quality == 'gray' ? 'sLUM' : 'sRGB'

        %(-rate #{rates_arg}
            -jp2_space #{jp2_space_arg}
            -double_buffering 10
            -num_threads 4
            -no_weights
            Clevels=#{levels_arg}
            "Stiles={#{tiles_arg}}"
            "Cblk={64,64}"
            Cuse_sop=yes
            Cuse_eph=yes
            Corder=RPCL
            ORGgen_plt=yes
            ORGtparts=R  ).gsub(/\s+/, " ").strip
      end

      def level_count_for_size(long_dim)
        return 0 if long_dim < 96
        levels = 0
        level_size = long_dim
        while level_size >= 96
          level_size /= 2
          levels += 1
        end
        levels - 1
      end

      def layer_rates(layer_count, compression_numerator)
        # e.g. if compression_numerator = 10 then compression is 10:1
        rates = []
        cmp = 24.0 / compression_numerator
        layer_count.times do
          rates << cmp
          cmp = (cmp / 1.618).round(8)
        end
        rates.map(&:to_s).join(',')
      end

      def encode(path, recipe, output_file)
        kdu_compress = Hydra::Derivatives.kdu_compress_path
        execute "#{kdu_compress} -quiet -i #{Shellwords.escape(path)} -o #{output_file} #{recipe}"
      end

      def tmp_file(ext)
        Dir::Tmpname.create(['sufia', ext], Hydra::Derivatives.temp_file_base) {}
      end

      def long_dim(image)
        [image[:width], image[:height]].max
      end
    end

    def process
      image = MiniMagick::Image.open(source_path)
      quality = image['%[channels]'] == 'gray' ? 'gray' : 'color'
      long_dim = self.class.long_dim(image)
      file_path = self.class.tmp_file('.tif')
      to_srgb = directives.fetch(:to_srgb, true)
      preprocess(image, resize: directives[:resize], to_srgb: to_srgb, src_quality: quality) if directives[:resize] || to_srgb
      image.write file_path
      recipe = self.class.kdu_compress_recipe(directives, quality, long_dim)
      encode_file(recipe, file_path: file_path)
      File.unlink(file_path) unless file_path.nil?
    end

    def encode_file(recipe, file_path:)
      output_file = self.class.tmp_file('.jp2')
      self.class.encode(file_path, recipe, output_file)
      output_file_service.call(File.open(output_file, 'rb'), directives)
      File.unlink(output_file)
    end

    protected

      def preprocess(image, opts = {})
        # resize: <geometry>, to_srgb: <bool>, src_quality: 'color'|'gray'
        image.combine_options do |c|
          c.resize(opts[:resize]) if opts[:resize]
          c.profile self.class.srgb_profile_path if opts[:src_quality] == 'color' && opts[:to_srgb]
        end
        image
      end
  end
end
