# frozen_string_literal: true
module Hydra::Derivatives
  class DocumentDerivatives < Runner
    def self.processor_class
      Processors::Document
    end
  end
end
