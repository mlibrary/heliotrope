module Riiif
  # Transforms an image using a backend
  class AbstractTransformer
    # @param path [String] The path of the source image file
    # @param image_info [ImageInformation] information about the source
    # @param [Transformation] transformation
    def self.transform(path, image_info, transformation)
      new(path, image_info, transformation).transform
    end

    def initialize(path, image_info, transformation)
      @path = path
      @image_info = image_info
      @transformation = transformation
    end

    attr_reader :path, :image_info, :transformation

    def transform
      execute(command_builder.command)
    end

    def command_builder
      @command_builder ||= command_factory.new(path, image_info, transformation)
    end

    delegate :execute, to: Riiif::CommandRunner
    private :execute
  end
end
