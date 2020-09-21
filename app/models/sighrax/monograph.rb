# frozen_string_literal: true

# See en.csv.descriptions in ./config/locales/heliotrope.en.yml for metadata field descriptions

module Sighrax
  class Monograph < Work
    private_class_method :new

    def cover_representative
      @cover_representative ||= Sighrax.from_noid(Array(data['representative_id_ssim']).first)
    end

    def epub_featured_representative
      @epub_featured_representative ||= Sighrax.from_noid(FeaturedRepresentative.find_by(work_id: noid, kind: 'epub')&.file_set_id)
    end

    def pdf_ebook_featured_representative
      @pdf_ebook_featured_representative ||= Sighrax.from_noid(FeaturedRepresentative.find_by(work_id: noid, kind: 'pdf_ebook')&.file_set_id)
    end

    def contributors
      Array(data['creator_tesim']) + Array(data['contributor_tesim'])
    end

    def description
      Array(data['description_tesim']).first
    end

    def identifier
      return @identifier if @identifier.present?

      @identifier = Array(data['doi_sim']).first
      @identifier ||= Array(data['hdl_sim']).first
      @identifier ||= HandleNet.url(noid)
      @identifier
    end

    def language
      Array(data['language_tesim']).first
    end

    def published
      m = /\d{4}/.match(Array(data['date_created_tesim']).first)
      Date.parse("#{m}-01-01")
    rescue StandardError => _e
      nil
    end

    def publisher
      Array(data['publisher_tesim']).first
    end

    def series
      Array(data['series_tesim']).first
    end

    def subjects
      Array(data['subject_tesim'])
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
