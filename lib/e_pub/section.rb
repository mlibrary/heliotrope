# frozen_string_literal: true

module EPub
  class Section
    private_class_method :new

    # Class Methods

    def self.from_rendition_cfi_title(rendition, cfi, title) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return null_object unless rendition&.instance_of?(Rendition) && cfi&.instance_of?(String) && cfi.present? && title&.instance_of?(String) && title.present?
      rendition.sections.each do |section|
        next unless section.cfi == cfi
        next unless section.title == title
        return section
      end
      null_object
    end

    def self.from_rendition_args(rendition, args)
      return null_object unless rendition&.instance_of?(Rendition) && args&.instance_of?(Hash)
      new(rendition, args)
    end

    def self.null_object
      SectionNullObject.send(:new)
    end

    # Instance Methods

    def title
      @args[:title] || ''
    end

    def level
      @args[:depth] || 0
    end

    def cfi
      @args[:cfi] || ''
    end

    def downloadable?
      downloadable_pages.count.positive? || false
    end

    def pages
      @pages ||= @args[:unmarshaller_chapter]&.pages&.map { |unmarshaller_page| Page.from_section_unmarshaller_page(self, unmarshaller_page) } || []
    end

    def downloadable_pages
      @downloadable_pages ||= @args[:unmarshaller_chapter]&.downloadable_pages&.map { |unmarshaller_page| Page.from_section_unmarshaller_page(self, unmarshaller_page) } || []
    end

    private

      def initialize(rendition, args)
        @rendition = rendition
        @args = args
      end
  end

  class SectionNullObject < Section
    private_class_method :new

    private

      def initialize
        super(Rendition.null_object, unmarshaller_chapter: Unmarshaller::Chapter.null_object)
      end
  end
end
