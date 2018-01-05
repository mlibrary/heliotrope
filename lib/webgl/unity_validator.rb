# frozen_string_literal: true

require 'find'

module Webgl
  class UnityValidator
    attr_reader :id, :progress, :loader, :json

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

    def self.null_object
      UnityValidatorNullObject.new
    end

    private

      def initialize(opts)
        @id       = opts[:id]
        @progress = opts[:progress]
        @loader   = opts[:loader]
        @json     = opts[:json]
      end
  end

  class UnityValidatorNullObject
    attr_reader :id, :progress, :loader, :json
    def initialize
      @id = nil
      @progress = nil
      @loader = nil
      @json = nil
    end
  end
end
