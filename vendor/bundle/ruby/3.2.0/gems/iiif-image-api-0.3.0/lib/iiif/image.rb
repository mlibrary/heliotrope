require 'active_support/all'
require 'iiif/image/version'

module IIIF
  module Image
    extend ActiveSupport::Autoload
    autoload :Region
    autoload :Size

    autoload_under 'models' do
      autoload :URI
      autoload :Transformation
      autoload :ImageRequestUri
      autoload :Dimension
    end

    autoload_under 'services' do
      autoload :OptionDecoder
    end

    class InvalidAttributeError < StandardError; end
  end
end
