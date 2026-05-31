# frozen_string_literal: true
module ActiveEncode
  # == Active Encode adapters
  #
  # Active Encode has adapters for the following engines:
  #
  #
  #
  module EngineAdapters
    extend ActiveSupport::Autoload

    autoload :MatterhornAdapter
    autoload :ZencoderAdapter
    autoload :ElasticTranscoderAdapter
    autoload :TestAdapter
    autoload :FfmpegAdapter
    autoload :MediaConvertAdapter
    autoload :PassThroughAdapter

    ADAPTER = 'Adapter'
    private_constant :ADAPTER

    class << self
      def lookup(name)
        const_get(name.to_s.camelize << ADAPTER)
      end
    end
  end
end
