# frozen_string_literal: true

module Sighrax
  class NullPublisher < Publisher
    private_class_method :new

    def work_noids(recursive = false)
      []
    end

    def resource_noids(recursive = false)
      []
    end

    def user_ids(recursive = false)
      []
    end

    def name
      'Null Publisher Name'
    end

    def watermark?
      false
    end

    def epub_chapter_downloads?
      false
    end

    def pdf_chapter_downloads?
      false
    end

    def tombstone_message
      nil
    end

    private

      def initialize(subdomain)
        super(subdomain, nil)
      end
  end
end
