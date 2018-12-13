# frozen_string_literal: true

module FeaturedRepresentatives
  module FileSetPresenter
    extend ActiveSupport::Concern
    attr_reader :fr

    def featured_representative
      @fr ||= FeaturedRepresentative.where(monograph_id: monograph_id, file_set_id: id).first
    end

    def featured_representative?
      featured_representative ? true : false
    end

    def component?
      component.positive?
    end

    def component
      return 0 unless epub?
      epub_component = Component.find_by(noid: id)
      return 0 if epub_component.blank?
      epub_component.id
    end

    def epub?
      # ['application/epub+zip'].include? mime_type
      featured_representative&.kind == 'epub'
    end

    def webgl?
      # ['application/zip', 'application/octet-stream'].include?(mime_type) && File.extname(original_name) == ".unity"
      featured_representative&.kind == 'webgl'
    end

    def pdf_ebook?
      featured_representative&.kind == 'pdf_ebook'
    end

    def mobi?
      featured_representative&.kind == 'mobi'
    end
  end
end
