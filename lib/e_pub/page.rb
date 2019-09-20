# frozen_string_literal: true

module EPub
  class Page
    private_class_method :new

    # Class Methods

    def self.from_interval_unmarshaller_page(interval, unmarshaller_page)
      return null_object unless interval&.instance_of?(Interval) && unmarshaller_page&.instance_of?(Unmarshaller::Page)
      new(interval, unmarshaller_page)
    end

    def self.null_object
      PageNullObject.send(:new)
    end

    # Instance Methods

    def image
      @unmarshaller_page.image
    end

    private
      def initialize(interval, unmarshaller_page)
        @interval = interval
        @unmarshaller_page = unmarshaller_page
      end
  end

  class PageNullObject < Page
    private_class_method :new

    private
      def initialize
        super(Interval.null_object, Unmarshaller::Page.null_object)
      end
  end
end
