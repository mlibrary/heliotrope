# frozen_string_literal: true

# See en.csv.descriptions in ./config/locales/heliotrope.en.yml for metadata field descriptions

module Sighrax
  class Monograph < Work
    private_class_method :new

    # Priority order for ISBN types (most to least preferred), pre-downcased for efficient lookup.
    # Generally we're looking for OA ebook, ebook, hardcover then paperback.
    # The list below was generated from actual Monograph metadata in Fulcrum.
    # Ordering reflects the intended preference of label families seen in metadata; it is not
    # strictly "most specific before most generic", and some generic labels intentionally outrank
    # more specific variants to preserve current matching behavior.
    ISBN_PRIORITY = [
      'open access',
      'open-access',
      'oa',
      'ebook epub',
      'e-book',
      'ebook',
      'ebook pdf',
      'pdf',
      'hardcover : alk. paper',
      'hc. : alk. paper',
      'cloth',
      'hardcover',
      'print',
      'paperback',
      'pb. : alk. paper',
      'pb.',
      'paper',
      'paper with cd',
      'paper plus cd rom',
      'none'
    ].freeze

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
      @identifier ||= HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + noid.to_s
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

    def product_ids
      # We could do this as above via Greensub::Product.containing_monograph(noid)
      # but I think this works too and is faster since it's already on the monograph
      vector('products_lsim')
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

      # Build a normalized (downcased) lookup map once to avoid repeated downcase calls
      normalized_isbns = parsed_isbns.transform_keys(&:downcase)

      # Find the first ISBN type that matches our priority list
      found_type = ISBN_PRIORITY.find { |isbn_type| normalized_isbns.key?(isbn_type) }
      isbn = normalized_isbns[found_type] if found_type

      # If no match found, use the first available ISBN
      isbn || parsed_isbns.values[0]
    end

    def non_preferred_isbns
      isbns = vector('isbn_tesim')
      return [] if isbns.empty?
      return [] if isbns.first.blank?

      parsed_isbns = parse_isbns(isbns)
      return [] if parsed_isbns.blank?
      normalized_isbns = parsed_isbns.transform_keys(&:downcase)
      found_type = ISBN_PRIORITY.find { |isbn_type| normalized_isbns.key?(isbn_type) }
      preferred = normalized_isbns[found_type] if found_type
      preferred ||= parsed_isbns.values.first
      others = parsed_isbns.values.dup
      others.delete(preferred)
      others
    end

    # EPUB Accessibility metadata accessors
    def epub_a11y_accessibility_summary
      scalar('epub_a11y_accessibility_summary_ssi')
    end

    def epub_a11y_conforms_to
      scalar('epub_a11y_conforms_to_ssi')
    end

    def epub_a11y_accessibility_features
      vector('epub_a11y_accessibility_feature_ssim')
    end

    def epub_a11y_accessibility_hazards
      vector('epub_a11y_accessibility_hazard_ssim')
    end

    def epub_a11y_access_modes
      vector('epub_a11y_access_mode_ssim')
    end

    def epub_a11y_access_modes_sufficient
      vector('epub_a11y_access_mode_sufficient_ssim')
    end

    # For PDFs
    # TODO: These fields don't actually exist yet but will be populated when
    # PDF accessibility metadata extraction is implemented.
    def pdf_a11y_accessibility_summary
      scalar('pdf_a11y_accessibility_summary_ssi')
    end

    def pdf_a11y_conforms_to
      scalar('pdf_a11y_conforms_to_ssi')
    end

    def pdf_a11y_accessibility_features
      vector('pdf_a11y_accessibility_feature_ssim')
    end

    def pdf_a11y_accessibility_hazards
      vector('pdf_a11y_accessibility_hazard_ssim')
    end

    def pdf_a11y_access_modes
      vector('pdf_a11y_access_mode_ssim')
    end

    def pdf_a11y_access_modes_sufficient
      vector('pdf_a11y_access_mode_sufficient_ssim')
    end

    private

      def initialize(noid, data)
        super(noid, data)
      end

      def parse_isbns(isbns) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        flag = false
        rvalue = {}
        isbns.each do |isbn|
          # Updated regex to capture multi-word types within parentheses
          # Matches: "ISBN (type with spaces)" where type can contain spaces
          # This should also preserve ISBN-10 X check digits should they be present
          m = /\s*(\S+)\s+\(\s*([^)]+?)\s*\)(.*)/.match(isbn)
          if m.blank? || m[1].blank? || m[2].blank?
            next if flag

            value = isbn.gsub(/[^0-9Xx]/, '')
            next if value.blank?

            rvalue['none'] = value
            flag = true
          else
            key = m[2]
            value = m[1].gsub(/[^0-9Xx]/, '')
            rvalue[key] = value if value.present?
          end
        end
        rvalue
      end
  end
end
