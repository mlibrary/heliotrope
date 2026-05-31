# frozen_string_literal: true
require 'active_fedora'
require 'deprecation'

module Hydra
  module Derivatives
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    extend Deprecation
    self.deprecation_horizon = "hydra-derivatives 1.0"

    # Runners take a single input and produce one or more outputs
    # The runner typically accomplishes this by using one or more processors
    autoload_under 'runners' do
      autoload :ActiveEncodeDerivatives
      autoload :AudioDerivatives
      autoload :DocumentDerivatives
      autoload :FullTextExtract
      autoload :ImageDerivatives
      autoload :Jpeg2kImageDerivatives
      autoload :PdfDerivatives
      autoload :Runner
      autoload :VideoDerivatives
    end

    autoload :Processors
    autoload :Config
    autoload :Logger
    autoload :TempfileService
    autoload :IoDecorator
    autoload :AudioEncoder

    autoload_under 'services' do
      autoload :RetrieveSourceFileService
      autoload :RemoteSourceFile
      autoload :PersistOutputFileService
      autoload :PersistBasicContainedOutputFileService
      autoload :PersistExternalFileOutputFileService
      autoload :TempfileService
      autoload :MimeTypeService
    end

    # Raised if the timout elapses
    class TimeoutError < ::Timeout::Error; end

    def self.config
      @config ||= reset_config!
    end

    def self.reset_config!
      @config = Config.new
    end

    CONFIG_METHODS = %i[ffmpeg_path libreoffice_path temp_file_base fits_path kdu_compress_path
                        kdu_compress_recipes enable_ffmpeg source_file_service output_file_service active_encode_poll_time].freeze
    CONFIG_METHODS.each do |method|
      module_eval <<-RUBY
        def self.#{method}
          config.#{method}
        end
        def self.#{method}= val
          config.#{method}= val
        end
      RUBY
    end

    included do
      class_attribute :source_file_service
      self.source_file_service = Hydra::Derivatives.source_file_service
    end
  end
end
