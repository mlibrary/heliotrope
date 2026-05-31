# frozen_string_literal: true
module Hydra::Derivatives::Processors
  module Video
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Processor
      autoload :Config
    end
  end
end
