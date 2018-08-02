# frozen_string_literal: true

module EPub
  class Section
    private_class_method :new

    # Class Methods

    def self.from_cfi(publication, cfi)
      return null_object unless publication&.instance_of?(Publication) && cfi&.instance_of?(String)
      new(publication, Chapter.from_cfi(publication, cfi))
    end

    def self.from_chapter(publication, chapter)
      return null_object unless publication&.instance_of?(Publication) && chapter&.instance_of?(Chapter)
      new(publication, chapter)
    end

    def self.null_object
      SectionNullObject.send(:new)
    end

    # Instance Methods

    def title
      @chapter.title
    end

    def level
      1
    end

    def cfi
      @chapter&.basecfi || ''
    end

    def downloadable?
      /^\s*yes|y\s*$/i.match?(@publication.multi_rendition)
    end

    def pdf
      @chapter.pdf
    end

    private

      def initialize(publication, chapter)
        @publication = publication
        @chapter = chapter
      end
  end

  class SectionNullObject < Section
    private_class_method :new

    private

      def initialize
        super(Publication.null_object, Chapter.null_object)
      end
  end
end
