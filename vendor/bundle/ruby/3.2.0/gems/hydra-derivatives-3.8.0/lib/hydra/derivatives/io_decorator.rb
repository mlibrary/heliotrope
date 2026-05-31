# frozen_string_literal: true
# Naive implementation of IO wrapper class that adds mime_type and original_filename
# attributes. This is done to match the interface of ActionDispatch::HTTP::UploadedFile
# so the attributes do not have to be passed as additional arguments, and are attached
# properly to the object they describe.
#
#
#  Use SimpleDelegator to wrap the given class or instance
require 'delegate'

module Hydra
  module Derivatives
    class IoDecorator < SimpleDelegator
      extend Deprecation

      attr_accessor :mime_type, :original_filename
      alias original_name original_filename
      deprecation_deprecate original_name: 'original_name has been deprecated. Use original_filename instead. This will be removed in hydra-derivatives 4.0'
      alias original_name= original_filename=
      deprecation_deprecate "original_name=": 'original_name= has been deprecated. Use original_filename= instead. This will be removed in hydra-derivatives 4.0'

      def initialize(file, mime_type = nil, original_filename = nil)
        super(file)
        self.mime_type = mime_type
        self.original_filename = original_filename
      end
    end
  end
end
