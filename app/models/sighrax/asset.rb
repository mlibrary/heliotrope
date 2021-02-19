# frozen_string_literal: true

module Sighrax
  class Asset < Model
    private_class_method :new

    def parent
      Sighrax.from_noid(Array(data['monograph_id_ssim']).first)
    end

    def content
      original_file&.content || ''
    end

    def media_type
      original_file&.mime_type || 'text/plain'
    end

    def filename
      original_file&.file_name&.first || noid + '.txt'
    end

    def file_size
      original_file&.size
    end

    def downloadable?
      Array(data['external_resource_url_ssim']).first.blank?
    end

    def allow_download?
      downloadable? &&
        /^yes$/i.match?(Array(data['allow_download_ssim']).first)
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
