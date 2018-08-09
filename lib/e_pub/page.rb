# frozen_string_literal: true

module EPub
  class Page
    private_class_method :new

    # Class Methods

    def self.from_section_unmarshaller_page(section, unmarshaller_page)
      return null_object unless section&.instance_of?(Section) && unmarshaller_page&.instance_of?(Unmarshaller::Page)
      new(section, unmarshaller_page)
    end

    def self.null_object
      PageNullObject.send(:new)
    end

    # Instance Methods

    def image
      @unmarshaller_page.image
    end

    private

      def initialize(section, unmarshaller_page)
        @section = section
        @unmarshaller_page = unmarshaller_page
      end
  end

  class PageNullObject < Page
    private_class_method :new

    private

      def initialize
        super(Section.null_object, Unmarshaller::Page.null_object)
      end
  end
end
