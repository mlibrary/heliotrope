# frozen_string_literal: true
module Hydra::Derivatives
  class ImageDerivatives < Runner
    # Adds format: 'png' as the default to each of the directives
    def self.transform_directives(options)
      options.each do |directive|
        directive.reverse_merge!(format: 'png')
      end
      options
    end

    def self.processor_class
      Processors::Image
    end
  end
end
