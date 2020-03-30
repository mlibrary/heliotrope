# frozen_string_literal: true

module PDFEbook
  class Interval
    private_class_method :new

    # Class Methods
    def self.from_title_level_cfi(id, index, title, level, cfi)
      return null_object unless title&.instance_of?(String) && cfi&.instance_of?(String)
      new(id: id, index: index, title: title, depth: level, cfi: cfi)
    end

    def self.from_h(hash)
      self.from_title_level_cfi(hash['id'], hash['index'], hash['title'], hash['depth'], hash['cfi'])
    end

    def self.null_object
      IntervalNullObject.send(:new)
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
      File.exist?(File.join(UnpackService.root_path_from_noid(@args[:id], 'pdf_ebook_chapters'), @args[:index].to_s + '.pdf'))
    end

    def pages
      []
    end

    def downloadable_pages
      []
    end

    def to_h
      @args.to_h
    end

    private

      def initialize(args)
        @args = args
      end
  end

  class IntervalNullObject < Interval
    private_class_method :new

    private

      def initialize
        super({})
      end
  end
end
