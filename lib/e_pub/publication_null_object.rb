# frozen_string_literal: true

module EPub
  class PublicationNullObject < Publication
    private_class_method :new
    attr_reader :id, :content_file, :content, :toc

    # Instance Methods

    def chapters
      []
    end

    def read(_file_entry)
      ''
    end

    def search(query)
      { q: query, search_results: [] }
    end

    private

      def initialize
        @id = 'epub_null'
        @content_file = "empty"
        @content = Nokogiri::XML(nil)
        @toc = Nokogiri::XML(nil)
      end
  end
end
