# frozen_string_literal: true
module ActiveEncode
  module EngineAdapters
    module MediaConvertOutput
      class << self
        AUDIO_SETTINGS = {
          "AAC" => :aac_settings,
          "AC3" => :ac3_settings,
          "AIFF" => :aiff_settings,
          "EAC3_ATMOS" => :eac_3_atmos_settings,
          "EAC3" => :eac_3_settings,
          "MP2" => :mp_2_settings,
          "MP3" => :mp_3_settings,
          "OPUS" => :opus_settings,
          "VORBIS" => :vorbis_settings,
          "WAV" => :wav_settings
        }.freeze

        VIDEO_SETTINGS = {
          "AV1" => :av_1_settings,
          "AVC_INTRA" => :avc_intra_settings,
          "FRAME_CAPTURE" => :frame_capture_settings,
          "H_264" => :h264_settings,
          "H_265" => :h265_settings,
          "MPEG2" => :mpeg_2_settings,
          "PRORES" => :prores_settings,
          "VC3" => :vc_3_settings,
          "VP8" => :vp_8_settings,
          "VP9" => :vp_9_settings,
          "XAVC" => :xavc_settings
        }.freeze

        def tech_metadata(settings, output)
          url = output.dig('outputFilePaths', 0)
          {
            width: output.dig('videoDetails', 'widthInPx'),
            height: output.dig('videoDetails', 'heightInPx'),
            frame_rate: extract_video_frame_rate(settings),
            duration: output['durationInMs'],
            audio_codec: extract_audio_codec(settings),
            video_codec: extract_video_codec(settings),
            audio_bitrate: extract_audio_bitrate(settings),
            video_bitrate: extract_video_bitrate(settings),
            url: url,
            label: File.basename(url),
            suffix: settings.name_modifier
          }
        end

        def extract_audio_codec(settings)
          settings.audio_descriptions.first.codec_settings.codec
        rescue
          nil
        end

        def extract_audio_codec_settings(settings)
          codec_key = AUDIO_SETTINGS[extract_audio_codec(settings)]
          settings.audio_descriptions.first.codec_settings[codec_key]
        end

        def extract_video_codec(settings)
          settings.video_description.codec_settings.codec
        rescue
          nil
        end

        def extract_video_codec_settings(settings)
          codec_key = VIDEO_SETTINGS[extract_video_codec(settings)]
          settings.video_description.codec_settings[codec_key]
        rescue
          nil
        end

        def extract_audio_bitrate(settings)
          codec_settings = extract_audio_codec_settings(settings)
          return nil if codec_settings.nil?
          try(codec_settings, :bitrate)
        end

        def extract_video_bitrate(settings)
          codec_settings = extract_video_codec_settings(settings)
          return nil if codec_settings.nil?
          try(codec_settings, :bitrate) || try(codec_settings, :max_bitrate)
        end

        def extract_video_frame_rate(settings)
          codec_settings = extract_video_codec_settings(settings)
          return nil if codec_settings.nil?
          (codec_settings.framerate_numerator.to_f / codec_settings.framerate_denominator.to_f).round(2)
        rescue
          nil
        end

        private

        def try(struct, key)
          struct[key]
        rescue
          nil
        end
      end
    end
  end
end
