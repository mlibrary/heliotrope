# frozen_string_literal: true

# See en.csv.descriptions in ./config/locales/heliotrope.en.yml for metadata field descriptions

module Sighrax
  class Monograph < Work
    private_class_method :new

    def audiobook
      @audiobook ||= Sighrax.from_noid(FeaturedRepresentative.find_by(work_id: noid, kind: 'audiobook')&.file_set_id)
    end

    def buy_url
      scalar('buy_url_ssim') || ''
    end

    def contributors
      vector('creator_tesim') + vector('contributor_tesim')
    end

    def cover
      @cover ||= Sighrax.from_noid(scalar('representative_id_ssim'))
    end

    def description
      scalar('description_tesim') || ''
    end

    def ebook
      return @ebook if @ebook.present?
      @ebook = epub_ebook
      @ebook = pdf_ebook if @ebook.is_a?(Sighrax::NullEntity)
      @ebook
    end

    def epub_ebook
      @epub_ebook ||= Sighrax.from_noid(FeaturedRepresentative.find_by(work_id: noid, kind: 'epub')&.file_set_id)
    end

    def identifier
      return @identifier if @identifier.present?

      @identifier = HandleNet::DOI_ORG_PREFIX + scalar('doi_ssim') if scalar('doi_ssim').present?
      @identifier ||= HandleNet::HANDLE_NET_PREFIX + scalar('hdl_ssim') if scalar('hdl_ssim').present?
      @identifier ||= HandleNet.url(noid)
      @identifier
    end

    def languages
      vector('language_tesim')
    end

    def modified
      # Going to leverage the aptrust_deposits table updated_at field
      # since this is the modify date of the entire monograph a.k.a.
      # Maximum date_modified_dtsi of the Monograph and all its FileSets. .
      record = AptrustDeposit.find_by(noid: noid)
      return record.updated_at.utc if record.present?

      super
    end

    def open_access?
      /^yes$/i.match?(scalar('open_access_tesim'))
    end

    def pdf_ebook
      @pdf_ebook ||= Sighrax.from_noid(FeaturedRepresentative.find_by(work_id: noid, kind: 'pdf_ebook')&.file_set_id)
    end

    def products
      Greensub::Product.containing_monograph(noid)
    end

    def publication_year
      match = /(\d{4})/.match(scalar('date_created_tesim'))
      return match[1] if match.present?

      nil
    end

    def published
      Time.parse(scalar('date_published_dtsim')).utc
    rescue StandardError => _e
      nil
    end

    # This solr field 'publisher_tesim' is the name of the company that created the work.
    # Not to be confused with 'subdomain' which is the 'press' a.k.a. Fulcrum Publisher.
    def publishing_house
      scalar('publisher_tesim') || ''
    end

    def restricted?
      Greensub::Component.find_by(noid: noid).present?
    end

    def series
      scalar('series_tesim') || ''
    end

    def subjects
      vector('subject_tesim')
    end

    def worldcat_url
      isbn = preferred_isbn
      return '' if isbn.empty?

      'http://www.worldcat.org/isbn/' + preferred_isbn
    end

    def preferred_isbn
      # Build your link around the 10- or 13-digit ISBN for the item.
      isbns = vector('isbn_tesim')
      return '' if isbns.empty?

      return '' if isbns.first.blank?

      parsed_isbns = parse_isbns(isbns)
      return '' if parsed_isbns.blank?

      isbn = nil
      %w[ebook hardcover paper none].each do |key|
        isbn = parsed_isbns[key]
        break if isbn.present?
      end
      isbn ||= parsed_isbns.values[0]
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end

      def parse_isbns(isbns) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        flag = false
        rvalue = {}
        isbns.each do |isbn|
          m = /\s*(\S+)\s+\(\s*(\S+)\s*\)(.*)/.match(isbn)
          if m.blank? || m[1].blank? || m[2].blank?
            next if flag

            value = isbn.gsub(/\D/, '')
            next if value.blank?

            rvalue['none'] = value
            flag = true
          else
            key = m[2]
            value = m[1].gsub(/\D/, '') || m[1]
            rvalue[key] = value if value.present?
          end
        end
        rvalue
      end
  end
end
