module IIIF::Image
  module Region
    extend ActiveSupport::Autoload
    autoload :Absolute
    autoload :Full
    autoload :Percent
    autoload :Square
  end
end
