module IIIF::Image
  module Size
    extend ActiveSupport::Autoload
    autoload :Absolute
    autoload :BestFit
    autoload :Full
    autoload :Height
    autoload :Max
    autoload :Percent
    autoload :Width
  end
end
