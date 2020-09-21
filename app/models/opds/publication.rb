# frozen_string_literal: true

module Opds
  class Publication
    private_class_method :new

    delegate :to_json, to: :to_h

    class << self
      def new_from_monograph(monograph)
        Publication.send(:new, monograph)
      end
    end

    def valid? # rubocop:disable Metrics/CyclomaticComplexity
      return false unless @monograph.is_a?(::Sighrax::Monograph)
      return false unless ::Sighrax.published?(@monograph)
      return false unless ::Sighrax.open_access?(@monograph)
      return false unless @monograph.cover_representative.valid?
      return false unless @monograph.epub_featured_representative.valid? || @monograph.pdf_ebook_featured_representative.valid?
      true
    end

    def to_h
      raise StandardError.new('Invalid OPDS Publication') unless valid?

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
      rvalue[:metadata][:imprint] = imprint
      rvalue[:metadata][:language] = language
      rvalue[:metadata][:modified] = modified
      rvalue[:metadata][:numberOfPages] = numberOfPages
      rvalue[:metadata][:published] = published
      rvalue[:metadata][:publisher] = publisher
      rvalue[:metadata][:readingProgression] = readingProgression
      rvalue[:metadata][:subject] = subject
      rvalue[:metadata][:subtitle] = subtitle

      rvalue[:metadata].delete_if { |k, v| v.blank? }

      if @monograph.epub_featured_representative.valid?
        rvalue[:links].append({ rel: 'self', href: download_ebook_url(@monograph.epub_featured_representative), type: 'application/epub+zip' })
        rvalue[:links].append({ rel: 'http://opds-spec.org/acquisition/open-access', href: download_ebook_url(@monograph.epub_featured_representative), type: 'application/epub+zip' })
        if @monograph.pdf_ebook_featured_representative.valid?
          rvalue[:links].append({ rel: 'http://opds-spec.org/acquisition/open-access', href: download_ebook_url(@monograph.pdf_ebook_featured_representative), type: 'application/pdf' })
        end
      elsif @monograph.pdf_ebook_featured_representative.valid?
        rvalue[:links].append({ rel: 'self', href: download_ebook_url(@monograph.pdf_ebook_featured_representative), type: 'application/pdf' })
        rvalue[:links].append({ rel: 'http://opds-spec.org/acquisition/open-access', href: download_ebook_url(@monograph.pdf_ebook_featured_representative), type: 'application/pdf' })
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
        'http:://schema.org/EBook'
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
        # plain text
        # description_tesim
        return nil if @monograph.description.blank?
        MarkdownService.markdown_as_text(@monograph.description, true)
      end

      def duration
        # seconds
        nil
      end

      def identifier
        # doi_sim
        # hdl_sim
        # identifier_tesim
        @monograph.identifier # "https://uri"
      end

      def imprint
      end

      def language
        # BCP 47 e.g. 'en'
        # language_tesim
        return nil if @monograph.language.blank?
        return 'en' if /\s*(en)(glish)?\s*/i.match?(@monograph.language)
        nil
      end

      def modified
        # ISO 8601
        # timestamp
        # system_create_dtsi
        # system_modified_dtsi
        # date_uploaded_dtsi
        # date_modified_dtsi
      end

      def numberOfPages
      end

      def published
        # ISO 8601
        # date_created_tesim
        @monograph.published&.iso8601
      end

      def publisher
        # publisher_tesim
        @monograph.publisher
      end

      def readingProgression
        # 'ltr', 'rtl', 'ttb', 'btt', or 'auto' (default)
      end

      def series
        # optional links
        # see also belongsTo and collection
        # series_tesim
        @monograph.series
      end

      def subject
        # subject_tesim
        return nil if @monograph.subjects.blank?
        return @monograph.subjects.first if @monograph.subjects.count == 1
        @monograph.subjects
      end

      def subtitle
      end

      def title
        # title_tesim
        # {
        #     en: @monograph.title
        # }
        # MarkdownService.markdown_as_text(@monograph.title, true)
        @monograph.title
      end

      def title_sort_as
      end

      def download_ebook_url(ebook)
        Rails.application.routes.url_helpers.download_ebook_url(ebook.noid)
      end

      def monograph_image_url(monograph, width_size = 'full')
        width_size_string = width_size == 'full' ? 'full' : "#{width_size},"
        Riiif::Engine.routes.url_helpers.image_url(monograph.cover_representative.noid, host: Rails.application.routes.url_helpers.root_url, size: width_size_string, format: 'jpg')
      end

      def initialize(monograph)
        @monograph = monograph
      end
  end
end
