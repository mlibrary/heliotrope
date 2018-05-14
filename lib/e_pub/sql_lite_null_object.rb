# frozen_string_literal: true

module EPub
  class SqlLiteNullObject < SqlLite
    private_class_method :new
    attr_accessor :epub_publication, :db

    def create_table; end

    def load_chapters; end

    def search_chapters(_query)
      []
    end

    private

      def initialize
        @epub_publication = EPub::PublicationNullObject.send(:new)
        @db = nil
      end
  end
end
