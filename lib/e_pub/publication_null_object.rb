# frozen_string_literal: true

module EPub
  class PublicationNullObject < Publication
    private_class_method :new
    attr_reader :id, :container, :content_file, :content_dir, :content, :epub_path, :toc

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
      end
  end
end
