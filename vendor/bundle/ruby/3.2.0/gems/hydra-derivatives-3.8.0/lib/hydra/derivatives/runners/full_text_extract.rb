# frozen_string_literal: true
module Hydra::Derivatives
  class FullTextExtract < ImageDerivatives
    # Adds format: 'txt' as the default to each of the directives
    def self.transform_directives(options)
      options.each do |directive|
        directive.reverse_merge!(format: 'txt', binary: false)
      end
      options
    end

    def self.processor_class
      Processors::FullText
    end
  end
end
