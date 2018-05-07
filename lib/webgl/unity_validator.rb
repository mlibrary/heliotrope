# frozen_string_literal: true

require 'find'

module Webgl
  class UnityValidator
    attr_reader :id, :progress, :loader, :json, :root_path

    def self.from(id)
      if File.join(Webgl.path(id), "TemplateData", "UnityProgress.js").blank?
        ::Webgl.logger.info("#{id} is missing UnityProgress.js")
        return null_object
      end

      if File.join(Webgl.path(id), "Build", "UnityLoader.js").blank?
        ::Webgl.logger.info("#{id} is missing UnityLoader.js")
        return null_object
      end

      json_file = Find.find(File.join(Webgl.path(id), "Build")).map { |f| f if File.extname(f) == ".json" }.compact&.first
      if json_file.blank?
        ::Webgl.logger.info("#{id} is missing Unity .json file")
        return null_object
      end

      new(id: id,
          progress: File.join("TemplateData", "UnityProgress.js"),
          loader: File.join("Build", "UnityLoader.js"),
          json: File.join("Build", File.basename(json_file)))
    end

    def self.from_directory(root_path)
      return null_object unless Dir.exist? root_path

      if File.join(root_path, "TemplateData", "UnityProgress.js").blank?
        ::Webgl.logger.info("#{root_path} is missing UnityProgress.js")
        return null_object
      end

      if File.join(root_path, "Build", "UnityLoader.js").blank?
        ::Webgl.logger.info("#{root_path} is missing UnityLoader.js")
        return null_object
      end

      json_file = Find.find(File.join(root_path, "Build"))&.map { |f| f if File.extname(f) == ".json" }&.compact&.first
      if json_file.blank?
        ::Webgl.logger.info("#{root_path} is missing Unity .json file")
        return null_object
      end

      new(id: root_path_to_noid(root_path),
          progress: File.join("TemplateData", "UnityProgress.js"),
          loader: File.join("Build", "UnityLoader.js"),
          json: File.join("Build", File.basename(json_file)),
          root_path: root_path)
    end

    def self.null_object
      UnityValidatorNullObject.new
    end

    def self.root_path_to_noid(root_path)
      root_path.gsub(/-webgl/, '').split('/').slice(-5, 5).join('')
    end

    private

      def initialize(opts)
        @id       = opts[:id]
        @progress = opts[:progress]
        @loader   = opts[:loader]
        @json     = opts[:json]
        @root_path = opts[:root_path]
      end
  end

  class UnityValidatorNullObject
    attr_reader :id, :progress, :loader, :json, :root_path
    def initialize
      @id = nil
      @progress = nil
      @loader = nil
      @json = nil
      @root_path = nil
    end
  end
end
