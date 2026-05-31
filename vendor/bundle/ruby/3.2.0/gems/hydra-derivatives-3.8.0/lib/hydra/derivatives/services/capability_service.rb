# frozen_string_literal: true
require 'open3'

module Hydra::Derivatives
  class CapabilityService
    attr_accessor :ffmpeg_output
    def capture_output
      @ffmpeg_output = Open3.capture3('ffmpeg -codecs').to_s
    rescue StandardError
      Logger.warn('Unable to find ffmpeg')
      @ffmpeg_output = ""
    end

    def fdk_aac?
      @ffmpeg_output.include?('--enable-libfdk-aac') || @ffmpeg_output.include?('--with-fdk-aac')
    end
  end
end
