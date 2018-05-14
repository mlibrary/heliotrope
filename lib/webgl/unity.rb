# frozen_string_literal: true

module Webgl
  class Unity
    private_class_method :new
    attr_accessor :id, :unity_progress, :unity_loader, :unity_json, :root_path

    def self.from_directory(root_path)
      ::Webgl.logger.info("Opening Webgl from directory #{root_path}")
      return null_object unless Dir.exist? root_path
      valid_webgl = UnityValidator.from_directory(root_path)
      return null_object if valid_webgl.is_a?(UnityValidatorNullObject)

      new(valid_webgl)
    rescue StandardError => e
      ::Webgl.logger.info("Unity.from_directory(#{root_path}) raised #{e} #{e.backtrace}")
      null_object
    end

    def self.null_object
      UnityNullObject.send(:new)
    end

    def file(file_entry)
      File.join(root_path, file_entry)
    end

    private

      def initialize(webgl)
        @id = webgl.id
        @unity_progress = webgl.progress
        @unity_loader = webgl.loader
        @unity_json = webgl.json
        @root_path = webgl.root_path
      end
  end

  class UnityNullObject < Unity
    private_class_method :new

    private

      def initialize
        @id = nil
        @unity_progress = nil
        @unity_loader = nil
        @unity_json = nil
        @root_path = nil
      end
  end
end
