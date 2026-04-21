# frozen_string_literal: true

module Opds
  class Publication # rubocop:disable Metrics/ClassLength
    attr_reader :monograph
    private_class_method :new

    delegate :to_json, to: :to_h

    class << self
      def new_from_monograph(monograph, entity_id = nil)
        Publication.send(:new, monograph, entity_id)
      end

      def to_iso_639_2(language)
        return 'eng' if /\s*(en)(g)(lish)\s*/i.match?(language)

        return 'frc' if /\s*(fr)(e)(nch)\s*/i.match?(language)
        return 'frc' if /\s*(frc)\s*/i.match?(language)

        return 'spa' if /\s*(spa)(nish)\s*/i.match?(language)
        return 'spa' if /\s*(es)(pa.ol)\s*/i.match?(language)

        nil
      end
    end

    def to_h
      rvalue = {
        metadata: {},
        links: [],
        images: []
      }

      # https://github.com/readium/webpub-manifest/blob/master/contexts/default/README.md
      # @type and title are required all other metadata is optional
      rvalue[:metadata][:@type] = at_type
      rvalue[:metadata][:title] = title
      rvalue[:metadata][:sortAs] = title_sort_as

      # Contributors
      rvalue[:metadata][:artist] = contributor(:artist)
      rvalue[:metadata][:author] = contributor(:author)
      rvalue[:metadata][:colorist] = contributor(:colorist)
      rvalue[:metadata][:contributor] = contributor(:other)
      rvalue[:metadata][:editor] = contributor(:editor)
      rvalue[:metadata][:illustrator] = contributor(:illustrator)
      rvalue[:metadata][:inker] = contributor(:inker)
      rvalue[:metadata][:letterer] = contributor(:letterer)
      rvalue[:metadata][:narrator] = contributor(:narrator)
      rvalue[:metadata][:penciler] = contributor(:penciler)
      rvalue[:metadata][:translator] = contributor(:translator)

      rvalue[:metadata][:belongsTo] = belongsTo

      rvalue[:metadata][:abridged] = abridged
      rvalue[:metadata][:description] = description
      rvalue[:metadata][:duration] = duration
      rvalue[:metadata][:identifier] = identifier
      rvalue[:metadata][:altIdentifier] = altIdentifier
      rvalue[:metadata][:imprint] = imprint
      rvalue[:metadata][:language] = language
      rvalue[:metadata][:layout] = layout
      rvalue[:metadata][:modified] = modified
      rvalue[:metadata][:numberOfPages] = numberOfPages
      rvalue[:metadata][:published] = published
      rvalue[:metadata][:publisher] = publisher
      rvalue[:metadata][:readingProgression] = readingProgression
      rvalue[:metadata][:subject] = subject
      rvalue[:metadata][:subtitle] = subtitle

      # Accessibility metadata for EPUBs only
      # https://github.com/readium/webpub-manifest/tree/master/contexts/default#accessibility-metadata
      if @monograph.epub_ebook.valid?
        accessibility_metadata = {
          summary: accessibility_summary,
          conformsTo: conforms_to,
          feature: accessibility_features,
          hazard: accessibility_hazards,
          accessMode: access_modes,
          accessModeSufficient: access_modes_sufficient
        }
        accessibility_metadata.delete_if { |k, v| v.blank? }
        rvalue[:metadata][:accessibility] = accessibility_metadata unless accessibility_metadata.empty?
      end

      # Accessibility metadata for PDFs only
      # TODO: These fields don't actually exist yet but will be populated when PDF accessibility metadata extraction is implemented.
      # Only add PDF accessibility metadata if EPUB accessibility metadata is not already in the feed.
      # This way, if an EPUB is present and has accessibility metadata, we use that. If the EPUB has none,
      # or there is no EPUB at all, we fall back to PDF accessibility metadata.
      if @monograph.pdf_ebook.valid? && rvalue[:metadata][:accessibility].blank?
        accessibility_metadata = {
          summary: pdf_accessibility_summary,
          conformsTo: pdf_conforms_to,
          feature: pdf_accessibility_features,
          hazard: pdf_accessibility_hazards,
          accessMode: pdf_access_modes,
          accessModeSufficient: pdf_access_modes_sufficient
        }
        accessibility_metadata.delete_if { |k, v| v.blank? }
        rvalue[:metadata][:accessibility] = accessibility_metadata unless accessibility_metadata.empty?
      end


      rvalue[:metadata].delete_if { |k, v| v.blank? }

      if @monograph.epub_ebook.valid?
        rvalue[:links].append({ rel: 'self', href: download_ebook_url(@monograph.epub_ebook), type: 'application/epub+zip' })
        rvalue[:links].append({ rel: acquisition_rel, href: download_ebook_url(@monograph.epub_ebook), type: 'application/epub+zip' })
        if @monograph.pdf_ebook.valid?
          rvalue[:links].append({ rel: acquisition_rel, href: download_ebook_url(@monograph.pdf_ebook), type: 'application/pdf' })
        end
      elsif @monograph.pdf_ebook.valid?
        rvalue[:links].append({ rel: 'self', href: download_ebook_url(@monograph.pdf_ebook), type: 'application/pdf' })
        rvalue[:links].append({ rel: acquisition_rel, href: download_ebook_url(@monograph.pdf_ebook), type: 'application/pdf' })
      else
        # We have "publications" or Monographs without any actual book in umpebc like: zc77ss45g, rx913r17x or z603r054w
        # I don't know if that really makes sense in the OPDS context, but here we are.
        # However some kind of acquisition link is required in OPDS.
        # https://github.com/opds-community/drafts/blob/master/opds-2.0.md#43-acquisition-links
        # I guess we can use http://opds-spec.org/acquisition and just point to the DOI? We'll see.
        # See HELIO-4443
        rvalue[:links].append({ rel: "http://opds-spec.org/acquisition", href: @monograph.citable_link })
      end

      rvalue[:images].append({ href: monograph_image_url(@monograph), type: "image/jpeg" })
      [200, 400, 800].each do |width_size|
        rvalue[:images].append({ href: monograph_image_url(@monograph, width_size), width: width_size, type: "image/jpeg" })
      end

      rvalue
    end

    private

      def belongsTo
        belongs_to = {}

        belongs_to[:collection] = collection
        belongs_to[:series] = series

        belongs_to.delete_if { |k, v| v.blank? }

        return belongs_to if belongs_to.present?

        nil
      end

      def abridged
        # return true if abridged, otherwise nil
        nil
      end

      def at_type
        'http://schema.org/EBook'
      end

      def collection
        # optional links
        # see also belongsTo and series
      end

      def contributor(flavor) # rubocop:disable Metrics/CyclomaticComplexity
        # optional links
        # creator_tesim + contributor_tesim
        # last name, first name (role)
        rvalue = []

        case flavor
        # when :artist
        # when :colorist
        # when :illustrator
        # when :inker
        # when :letterer
        # when :narrator
        # when :penciler
        # when :translator
        # when :other
        when :author
          @monograph.contributors.each do |contributor|
            rvalue.append(contributor) unless /\(\s*\S+\s*\)/i.match?(contributor)
          end
        when :editor
          @monograph.contributors.each do |contributor|
            m = /(\S+)(\s*\(\s*editor\s*\).*)/i.match(contributor)
            rvalue.append(m[1]) if m.present?
          end
        end

        return nil if rvalue.blank?
        return rvalue.first if rvalue.count == 1
        rvalue
      end

      def description
        # plain HTML text
        MarkdownService.markdown_as_text(
          "<div>" +
            MarkdownService.markdown(@monograph.description || "") +
            "<br><a href=\"" +
              MarkdownService.markdown_as_text(@monograph.citable_link, true) +
              "\">View on Fulcrum platform.</a></div>"
        )
      end

      def duration
        # seconds
        nil
      end

      def identifier
        # Use preferred ISBN if available, otherwise fallback to monograph identifier
        return "urn:isbn:#{@preferred_isbn}" if @preferred_isbn.present?
        @monograph.identifier
      end

      def altIdentifier
        identifiers = []

        # Add non-preferred ISBNs
        if @non_preferred_isbns.present?
          identifiers.concat(@non_preferred_isbns.map { |isbn| "urn:isbn:#{isbn}" })
        end

        # Add DOI/handle in short format, but only if identifier is using an ISBN
        # (if identifier is using the DOI/handle, don't duplicate it here)
        if @preferred_isbn.present?
          doi_or_handle = @monograph.identifier
          if doi_or_handle.present?
            if doi_or_handle.start_with?('https://doi.org/')
              identifiers << doi_or_handle.sub('https://doi.org/', 'urn:doi:')
            elsif doi_or_handle.start_with?('https://hdl.handle.net/')
              # There's no official or unofficial urn namespace for handle like there is for DOI
              # so we'll just use the full url instead.
              identifiers << doi_or_handle
            end
          end
        end

        return nil if identifiers.empty?
        identifiers
      end

      def imprint
      end

      def language
        # BCP 47
        # ISO 639-2
        # The US Library of Congress is the registration authority for ISO 639-2
        # ISO 639-2 Part 2: Alpha-3 code Library of Congress
        # HELIO-3483 Return 'eng' if language is blank
        language_tags = @monograph.languages&.map { |language| Opds::Publication.to_iso_639_2(language) } || []
        language_tags.delete_if { |language| language.nil? }
        return 'eng' if language_tags.blank?

        return language_tags.first if language_tags.count == 1

        language_tags.uniq
      end

      def modified
        # HELIO-3677 Fix OPDS feed based on James English feedback
        # 2. Publication’s metadata doesn’t include modified field.
        # This field is required by Circulation Manager
        # to be able to skip already processed items,
        # i.e. it processes only publications which modified time is
        # greater than the time when this publication was last processed.
        # Without a modified field Circulation Manager is not able to
        # process the feed correctly.
        @monograph.modified&.utc&.iso8601 ||
          @monograph.published&.utc&.iso8601 ||
            Time.now.utc.iso8601
      end

      def numberOfPages
      end

      def published
        year = @monograph.publication_year
        date = Date.parse("#{year}-01-01") if year.present?
        date&.iso8601
      end

      def publisher
        @monograph.publishing_house
      end

      def layout
        # Return 'reflowable' for EPUBs
        # In the past we had fixed (page image) EPUBs, but those have all been converted to PDF
        return 'reflowable' if @monograph.epub_ebook.valid?
        nil
      end

      def readingProgression
        # 'ltr', 'rtl', 'ttb', 'btt', or 'auto' (default)
        # Currently all Fulcrum books are read left to right
        return 'ltr' if @monograph.epub_ebook.valid?
        nil
      end

      def series
        # optional links
        # see also belongsTo and collection
        @monograph.series
      end

      def subject
        return nil if @monograph.subjects.blank?
        return @monograph.subjects.first if @monograph.subjects.count == 1
        @monograph.subjects
      end

      def subtitle
      end

      def title
        @monograph.title
      end

      def title_sort_as
      end

      def accessibility_summary
        @monograph.epub_a11y_accessibility_summary
      end

      def conforms_to
        value = @monograph.epub_a11y_conforms_to
        return nil if value.blank?
        # conformsTo should be an array according to the spec
        [value]
      end

      def accessibility_features
        values = @monograph.epub_a11y_accessibility_features
        return nil if values.blank?
        values
      end

      def accessibility_hazards
        values = @monograph.epub_a11y_accessibility_hazards
        return nil if values.blank?
        values
      end

      def access_modes
        values = @monograph.epub_a11y_access_modes
        return nil if values.blank?
        values
      end

      def access_modes_sufficient
        values = @monograph.epub_a11y_access_modes_sufficient
        return nil if values.blank?
        # Split comma-separated values into nested arrays
        # e.g., "textual,visual" becomes ["textual", "visual"]
        # but "textual" remains "textual"
        # This is from an example found in 2026-04-02 from
        # https://github.com/readium/webpub-manifest/tree/master/contexts/default#accessibility-metadata
        values.map do |value|
          if value.include?(',')
            value.split(',').map(&:strip)
          else
            value
          end
        end
      end

      def pdf_accessibility_summary
        @monograph.pdf_a11y_accessibility_summary
      end

      def pdf_conforms_to
        value = @monograph.pdf_a11y_conforms_to
        return nil if value.blank?
        # conformsTo should be an array according to the spec
        [value]
      end

      def pdf_accessibility_features
        values = @monograph.pdf_a11y_accessibility_features
        return nil if values.blank?
        values
      end

      def pdf_accessibility_hazards
        values = @monograph.pdf_a11y_accessibility_hazards
        return nil if values.blank?
        values
      end

      def pdf_access_modes
        values = @monograph.pdf_a11y_access_modes
        return nil if values.blank?
        values
      end

      def pdf_access_modes_sufficient
        values = @monograph.pdf_a11y_access_modes_sufficient
        return nil if values.blank?
        # Split comma-separated values into nested arrays
        # e.g., "textual,visual" becomes ["textual", "visual"]
        # but "textual" remains "textual"
        values.map do |value|
          if value.include?(',')
            value.split(',').map(&:strip)
          else
            value
          end
        end
      end

      def acquisition_rel
        # Return the appropriate acquisition rel based on whether the monograph is open access
        @monograph.open_access? ? 'http://opds-spec.org/acquisition/open-access' : 'http://opds-spec.org/acquisition'
      end

      def download_ebook_url(ebook)
        return Rails.application.routes.url_helpers.download_ebook_url(ebook.noid, entityID: @entity_id) if @entity_id
        Rails.application.routes.url_helpers.download_ebook_url(ebook.noid)
      end

      def monograph_image_url(monograph, width_size = 'full')
        width_size_string = width_size == 'full' ? 'full' : "#{width_size},"
        Riiif::Engine.routes.url_helpers.image_url(monograph.cover.noid, host: Rails.application.routes.url_helpers.root_url, size: width_size_string, format: 'jpg')
      end

      def initialize(monograph, entity_id = nil)
        @monograph = monograph
        @entity_id = entity_id
        # Memoize preferred and non-preferred ISBNs to avoid repeated parsing
        @preferred_isbn = @monograph.preferred_isbn
        @non_preferred_isbns = @monograph.non_preferred_isbns
      end
  end
end
