# frozen_string_literal: true

# see HELIO-2207, HELIO-2208
Hydra::Derivatives::Processors::Video::Processor.class_eval do
  prepend(HeliotropeVideoProcessorOverrides = Module.new do
    # source https://github.com/samvera/hydra-derivatives/blob/f781d112e05155c90d3de9c6bc05308864ecb1cf/lib/hydra/derivatives/processors/video/config.rb#L1

    protected

      def options_for(format)
        input_options = ""
        output_options = ""

        if format == "jpg"
          # we'll take the thumbnail and poster at 5 seconds instead of 2, as we still get a lot of blank...
          # thumbnails for slow-starting videos
          input_options += "-itsoffset -5"
          output_options += "-vframes 1 -an -f rawvideo"
        else
          # set pretty good bitrates across-the-board, will likely increase size of playback derivatives...
          # of low-res content, but no matter
          output_options += "-g 30 -b:v 1200k -ac 2 -ab 192k -ar 44100"
        end

        if directives.fetch(:label) == :thumbnail
          # get a thumbnail that is no longer squashed to 320x240 like the hydra-derivatives default, sets auto height
          scaling_options = "-filter_complex scale=320:-1"
        else
          # scale all video playback and poster derivatives to 720P resolution, without upscaling smaller stuff
          # `-2` ensures the height is divisible by 2, a requirement for many encoders like libx264
          scaling_options = "-filter_complex \"scale='iw*min(1, min(1280/iw, 720/ih))':-2\""
        end

        output_options = "#{scaling_options} #{codecs(format)} #{output_options}"

        { Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => output_options, Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => input_options }
      end
  end)
end
