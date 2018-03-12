# frozen_string_literal: true

module Webgl
  class Unity
    private_class_method :new
    attr_accessor :id, :unity_progress, :unity_loader, :unity_json

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

    def self.null_object
      UnityNullObject.send(:new)
    end

    def purge
      Cache.purge(id)
    end

    def read(file_entry, send_compressed = false)
      return Unity.null_object.read(file_entry) unless Cache.cached?(id)
      entry_file = ::Webgl.path_entry(id, file_entry)

      return Unity.null_object.read(entry_file) unless File.exist?(entry_file)

      compressed_file = entry_file + ".gz"

      if send_compressed && File.exist?(compressed_file)
        # ::Webgl.logger.debug("Sent compressed file: #{compressed_file}")
        File.read(compressed_file)
      else
        # ::Webgl.logger.debug("Sent UNcompressed file: #{entry_file}")
        File.read(entry_file)
      end
    end

    private

      def initialize(webgl)
        @id = webgl.id
        @unity_progress = webgl.progress
        @unity_loader = webgl.loader
        @unity_json = webgl.json
      end
  end

  class UnityNullObject
    private_class_method :new
    attr_accessor :id, :unity_progress, :unity_loader, :unity_json

    def read(_file_entry)
      ''
    end

    private

      def initialize
        @id = nil
        @unity_progress = nil
        @unity_loader = nil
        @unity_json = nil
      end
  end
end
