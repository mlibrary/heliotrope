# frozen_string_literal: true

module Webgl
  class Unity
    private_class_method :new
    attr_accessor :id, :unity_progress, :unity_loader, :unity_json, :root_path

    def self.clear_cache
      Cache.clear
    end

    def self.from(webgl)
      id = webgl[:id]
      file = webgl[:file]
      return null_object if id.blank? || file.blank?
      return null_object unless Valid.noid?(id)

      Cache.cache(id, file)
      return null_object unless Cache.cached?(id)

      valid_webgl = UnityValidator.from(id)
      return null_object if valid_webgl.is_a?(UnityValidatorNullObject)

      new(valid_webgl)
    end

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

    def purge
      Cache.purge(id)
    end

    def file(file_entry)
      if @root_path.present?
        file = File.join(root_path, file_entry)
      else
        return Unity.null_object.file(file_entry) unless Cache.cached?(id)
        file = ::Webgl.path_entry(id, file_entry)
      end
      return Unity.null_object.file(file) unless File.exist?(file)
      file
    end

    def read(file_entry)
      if @root_path.present?
        file = File.join(root_path, file_entry)
      else
        return Unity.null_object.read(file_entry) unless Cache.cached?(id)
        file = ::Webgl.path_entry(id, file_entry)
      end
      return Unity.null_object.read(file) unless File.exist?(file)
      File.read(file)
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

  class UnityNullObject
    private_class_method :new
    attr_accessor :id, :unity_progress, :unity_loader, :unity_json, :root_path

    def read(_file_entry)
      ''
    end

    def file(_file_entry)
      nil
    end

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
