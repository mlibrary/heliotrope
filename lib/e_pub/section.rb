# frozen_string_literal: true

module EPub
  class Section
    private_class_method :new

    # Class Methods

    def self.from_cfi(publication, cfi)
      return null_object unless publication&.instance_of?(Publication) && cfi&.instance_of?(String)
      publication.sections.each do |section|
        return section if section.cfi == cfi
      end
      null_object
    end

    def self.from_hash(publication, args)
      return null_object unless args.instance_of?(Hash)
      new(publication, args)
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
      @args[:downloadable] || false
    end

    def pdf
      return Chapter.null_object.pdf unless downloadable?
      chapter = Chapter.from_cfi(@publication, @args[:cfi])
      files = chapter.files_in_chapter
      images = chapter.images_in_files(files)
      # In Prawn, "LETTER" is 8.5x11 which is 612x792
      pdf = Prawn::Document.new(page_size: "LETTER", page_layout: :portrait, margin: 50)
      images.each do |img|
        pdf.image img, fit: [512, 692] # minus 100 for the margin
      end
      pdf
    end

    private

      def initialize(publication, args)
        @publication = publication
        @args = args
      end
  end

  class SectionNullObject < Section
    private_class_method :new

    private

      def initialize
        super(Publication.null_object, {})
      end
  end
end
