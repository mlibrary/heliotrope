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

    def products
      Greensub::Product.containing_monograph(noid)
    end

    # Don't want to call this press right now because the other things like it are direct field access
    def _press
      subdomain = Array(data['press_tesim']).first
      Press.find_by(subdomain: subdomain)
    end

    def identifier
      return @identifier if @identifier.present?

      @identifier = Array(data['doi_sim']).first
      @identifier ||= Array(data['hdl_sim']).first
      @identifier ||= HandleNet.url(noid)
      @identifier
    end

    def languages
      Array(data['language_tesim'])
    end

    def modified
      # Going to leverage the aptrust_deposits table created_at field
      # since this is the modify date of the entire monograph a.k.a.
      # Maximum date_modified_dtsi of Monograph and FileSets .
      record = AptrustDeposit.find_by(noid: noid)
      value = record&.created_at
      value ||= Time.parse(Array(data['date_modified_dtsi']).first) if Array(data['date_modified_dtsi']).first # rubocop:disable Rails/TimeZone
      value
    rescue StandardError => _e
      nil
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
