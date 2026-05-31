# frozen_string_literal: true
module Hydra::Derivatives
  module Processors
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Processor
    end

    autoload :ActiveEncode
    autoload :Audio
    autoload :Document
    autoload :Ffmpeg
    autoload :FullText
    autoload :Image
    autoload :Jpeg2kImage
    autoload :RawImage
    autoload :ShellBasedProcessor
    autoload :Video
  end
end
