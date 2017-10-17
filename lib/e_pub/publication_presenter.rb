# frozen_string_literal: true

module EPub
  class PublicationPresenter < Presenter
    private_class_method :new

    def id
      @publication.id
    end

    def chapters
      @publication.chapters.map { |chapter| chapter.presenter if chapter.title? }.compact
    end

    def content_dir
      File.dirname(@publication.content_file) || ""
    end

    private

      def initialize(publication = Publication.null_object)
        @publication = publication
      end
  end
end
