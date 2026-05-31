# frozen_string_literal: true
module Hydra::Derivatives::Processors::Video
  class Config
    attr_writer :video_bitrate, :video_attributes, :size_attributes, :audio_attributes

    def video_bitrate
      @video_bitrate ||= default_video_bitrate
    end

    def video_attributes
      @video_attributes ||= default_video_attributes
    end

    def size_attributes
      @size_attributes ||= default_size_attributes
    end

    def audio_attributes
      @audio_attributes ||= default_audio_attributes
    end

    def mpeg4
      audio_encoder = Hydra::Derivatives::AudioEncoder.new
      @mpeg4 ||= CodecConfig.new("-vcodec libx264 -acodec #{audio_encoder.audio_encoder}")
    end

    def webm
      @webm ||= CodecConfig.new('-vcodec libvpx -acodec libvorbis')
    end

    def mkv
      @mkv ||= CodecConfig.new('-vcodec ffv1')
    end

    def jpeg
      @jpeg ||= CodecConfig.new('-vcodec mjpeg')
    end

    class CodecConfig
      attr_writer :codec

      def initialize(default)
        @codec = default
      end

      attr_reader :codec
    end

    def default_video_attributes(bitrate = video_bitrate)
      "-g 30 -b:v #{bitrate}"
    end

    protected

      def default_video_bitrate
        '345k'
      end

      def default_size_attributes
        "320x240"
      end

      def default_audio_attributes
        "-ac 2 -ab 96k -ar 44100"
      end
  end
end
