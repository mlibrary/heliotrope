# frozen_string_literal: true

module Sighrax
  class Resource < Model
    private_class_method :new

    alias_attribute :filename, :file_name

    def allow_download?
      /^yes$/i.match?(scalar('allow_download_ssim'))
    end

    def content
      original_file&.content || ''
    end

    def downloadable?
      scalar('external_resource_url_ssim').blank?
    end

    def file_name
      original_file&.file_name&.first || 'null_file.txt'
    end

    def file_size
      original_file&.size || 0
    end

    def media_type
      original_file&.mime_type || 'text/plain'
    end

    def parent
      @parent ||= Sighrax.from_noid(scalar('monograph_id_ssim')) || Entity.null_entity
    end

    def watermarkable?
      false
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end

      def original_file
        @original_file ||= FileSet.find(noid).original_file
      rescue StandardError => _e
        nil
      end
  end
end
