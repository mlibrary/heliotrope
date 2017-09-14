# frozen_string_literal: true

module EPub
  class PublicationPresenter < Presenter
    private_class_method :new

    def id
      @publication.id
    end

    def chapters
      rvalue = []
      @publication.chapters.each do |chapter|
        rvalue << chapter.presenter
      end
      rvalue
    end

    private

      def initialize(publication = Publication.null_object)
        @publication = publication
      end
  end
end
