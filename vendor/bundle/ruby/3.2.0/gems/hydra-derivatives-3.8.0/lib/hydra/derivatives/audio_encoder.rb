# frozen_string_literal: true
require 'open3'

module Hydra::Derivatives
  class AudioEncoder
    def initialize
      @ffmpeg_output = Open3.capture3('ffmpeg -codecs').to_s
    rescue StandardError
      Logger.warn('Unable to find ffmpeg')
      @ffmpeg_output = ""
    end

    def audio_encoder
      audio_encoder = if fdk_aac?
                        'libfdk_aac'
                      else
                        'aac'
                      end
      audio_encoder
    end

    private

      def fdk_aac?
        @ffmpeg_output.include?('--enable-libfdk-aac') || @ffmpeg_output.include?('--with-fdk-aac')
      end
  end
end
