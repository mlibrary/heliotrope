# frozen_string_literal: true

module Sighrax
  class NullEntity < Entity
    private_class_method :new

    def allow_download?
      false
    end

    def children
      []
    end

    def content
      ''
    end

    def contributors
      []
    end

    def cover_representative
      Entity.null_entity
    end

    def deposited?
      true
    end

    def description
      ''
    end

    def downloadable?
      false
    end

    def epub_featured_representative
      Entity.null_entity
    end

    def file_name
      'null_file.txt'
    end

    def file_size
      0
    end

    def identifier
      HandleNet.url(noid)
    end

    def languages
      []
    end

    def media_type
      'text/plain'
    end

    def modified
      nil
    end

    # alias_attribute :monograph, :parent
    def monograph
      parent
    end

    def open_access?
      false
    end

    def parent
      Entity.null_entity
    end

    def pdf_ebook_featured_representative
      Entity.null_entity
    end

    def products
      []
    end


    def publication_year
      nil
    end
    def published?
      false
    end

    def published
      nil
    end

    def publisher
      Publisher.null_publisher
    end

    def publishing_house
      ''
    end

    def restricted?
      false
    end

    def series
      ''
    end

    def subjects
      []
    end

    def timestamp
      nil
    end

    def tombstone?
      false
    end

    def watermarkable?
      false
    end

    private

      def initialize(noid)
        super(noid, {})
      end
  end
end
