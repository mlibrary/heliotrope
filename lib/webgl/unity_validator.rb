# frozen_string_literal: true

require 'find'

module Webgl
  class UnityValidator
    attr_reader :id, :root_path, :loader, :data, :framework, :code

    def self.from_directory(root_path) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return null_object unless root_path.present? && Dir.exist?(root_path)

      if !Dir.exist?(File.join(root_path, "TemplateData"))
        ::Webgl.logger.info("#{root_path} is missing TemplateData folder")
        return null_object
      end

      build_path = File.join(root_path, "Build")

      if !Dir.exist?(build_path)
        ::Webgl.logger.info("#{root_path} is missing Build folder")
        return null_object
      end

      loader_file = Pathname.glob(File.join(build_path, '*.loader.js')).first
      if loader_file.blank?
        ::Webgl.logger.info("#{build_path} is missing Unity *.loader.js file")
        return null_object
      end

      data_file = Pathname.glob(File.join(build_path, '*.data')).first
      if data_file.blank?
        ::Webgl.logger.info("#{build_path} is missing Unity *.data file")
        return null_object
      end

      framework_file = Pathname.glob(File.join(build_path, '*.framework.js')).first
      if framework_file.blank?
        ::Webgl.logger.info("#{build_path} is missing Unity *.framework.js file")
        return null_object
      end

      code_file = Pathname.glob(File.join(build_path, '*.wasm')).first
      if code_file.blank?
        ::Webgl.logger.info("#{build_path} is missing Unity *.wasm file")
        return null_object
      end

      id = root_path_to_noid(root_path)

      new(id: id,
          loader: File.join(id, 'Build', File.basename(loader_file)),
          data: File.join(id, 'Build', File.basename(data_file)),
          framework: File.join(id, 'Build', File.basename(framework_file)),
          code: File.join(id, 'Build', File.basename(code_file)),
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
        @id        = opts[:id]
        @loader    = opts[:loader]
        @data      = opts[:data]
        @framework = opts[:framework]
        @code      = opts[:code]
        @root_path = opts[:root_path]
      end
  end

  class UnityValidatorNullObject < UnityValidator
    def initialize
      @id        = "webglnull"
      @loader    = nil
      @data      = nil
      @framework = nil
      @code      = nil
      @root_path = nil
    end
  end
end
