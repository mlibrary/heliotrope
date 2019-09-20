# frozen_string_literal: true

module PDFEbook
  class Interval
    private_class_method :new

    # Class Methods
    def self.from_title_level_cfi(title, level, cfi)
      return null_object unless title&.instance_of?(String) && cfi&.instance_of?(String)
      new(title: title, depth: level, cfi: cfi)
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
      false
    end

    def pages
      []
    end

    def downloadable_pages
      []
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
