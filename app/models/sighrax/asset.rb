# frozen_string_literal: true

module Sighrax
  class Asset < Model
    private_class_method :new

    def parent
      Sighrax.factory(Array(data['monograph_id_ssim']).first)
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
