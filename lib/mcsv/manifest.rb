# frozen_string_literal: true

module MCSV
  class Manifest
    private_class_method :new

    attr_reader :id

    # Class Methods

    def self.clear_cache; end

    def self.from(mcsv, options = {})
      return null_object if mcsv.blank?
      noid = if mcsv.is_a?(Hash)
               return null_object unless Valid.noid?(mcsv[:id])
               mcsv[:id]
             else
               return null_object unless Valid.noid?(mcsv)
               mcsv
             end
      new(noid.to_s)
    rescue StandardError => e
      ::MCSV.logger.info("Manifest.from(#{mcsv}, #{options}) raised #{e}")
      null_object
    end

    def self.null_object
      ManifestNullObject.send(:new)
    end

    # Instance Methods

    def purge; end

    private

      def initialize(id)
        @id = id
      end
  end
end
