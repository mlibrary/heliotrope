# frozen_string_literal: true

module FeaturedRepresentatives
  module MonographPresenter
    extend ActiveSupport::Concern
    attr_reader :frs

    def featured_representatives
      @frs ||= FeaturedRepresentative.where(monograph_id: id)
    end

    def epub?
      featured_representatives.map(&:kind).include? 'epub'
    end

    def epub
      ordered_member_docs.find { |doc| doc.id == epub_id }
    end

    def epub_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'epub' }.compact.first
    end

    def epub_presenter
      @epub_presenter ||= EPubPresenter.new(EPub::Publication.from_directory(UnpackService.root_path_from_noid(epub_id, 'epub')))
    end

    def webgl?
      featured_representatives.map(&:kind).include? 'webgl'
    end

    def webgl
      ordered_member_docs.find { |doc| doc.id == webgl_id }
    end

    def webgl_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'webgl' }.compact.first
    end

    def database?
      featured_representatives.map(&:kind).include? 'database'
    end

    def database
      return @database if @database.present?
      solr_doc = ordered_member_docs.find { |doc| doc.id == database_id }
      @database ||= Hyrax::FileSetPresenter.new(solr_doc, current_ability, request) if solr_doc.present?
    end

    def database_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'database' }.compact.first
    end

    def aboutware?
      featured_representatives.map(&:kind).include? 'aboutware'
    end

    def aboutware
      return @aboutware if @aboutware.present?
      solr_doc = ordered_member_docs.find { |doc| doc.id == aboutware_id }
      @aboutware ||= Hyrax::FileSetPresenter.new(solr_doc, current_ability, request) if solr_doc.present?
    end

    def aboutware_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'aboutware' }.compact.first
    end

    def reviews?
      featured_representatives.map(&:kind).include? 'reviews'
    end

    def reviews
      return @reviews if @reviews.present?
      solr_doc = ordered_member_docs.find { |doc| doc.id == reviews_id }
      @reviews ||= Hyrax::FileSetPresenter.new(solr_doc, current_ability, request) if solr_doc.present?
    end

    def reviews_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'reviews' }.compact.first
    end

    def related?
      featured_representatives.map(&:kind).include? 'related'
    end

    def related
      return @related if @related.present?
      solr_doc = ordered_member_docs.find { |doc| doc.id == related_id }
      @related ||= Hyrax::FileSetPresenter.new(solr_doc, current_ability, request) if solr_doc.present?
    end

    def related_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'related' }.compact.first
    end

    def pdf_ebook?
      featured_representatives.map(&:kind).include? 'pdf_ebook'
    end

    def pdf_ebook
      ordered_member_docs.find { |doc| doc.id == pdf_ebook_id }
    end

    def pdf_ebook_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'pdf_ebook' }.compact.first
    end

    def pdf_ebook_presenter
      entity = Sighrax.factory(pdf_ebook_id)
      @pdf_ebook_presenter ||= PDFEbookPresenter.new(PDFEbook::Publication.from_string_id(entity.content, pdf_ebook_id))
    end

    def mobi?
      featured_representatives.map(&:kind).include? 'mobi'
    end

    def mobi_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'mobi' }.compact.first
    end

    def peer_review?
      featured_representatives.map(&:kind).include? 'peer_review'
    end

    def peer_review
      return @peer_review if @peer_review.present?
      solr_doc = ordered_member_docs.find { |doc| doc.id == peer_review_id }
      @peer_review ||= Hyrax::FileSetPresenter.new(solr_doc, current_ability, request) if solr_doc.present?
    end

    def peer_review_id
      featured_representatives.map { |fr| fr.file_set_id if fr.kind == 'peer_review' }.compact.first
    end
  end
end
