# frozen_string_literal: true

module FeaturedRepresentatives
  module MonographPresenter # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern
    attr_reader :frs

    def featured_representatives
      @frs ||= FeaturedRepresentative.where(work_id: id)
    end

    def toc?
      if epub?
        epub_presenter.intervals?
      elsif pdf_ebook?
        pdf_ebook_presenter.intervals?
      else
        false
      end
    end

    def reader_ebook?
      reader_ebook_id.present?
    end

    def reader_ebook_id
      return @reader_ebook_id if @reader_ebook_id.present?
      epub_id = nil
      pdf_ebook_id = nil
      featured_representatives.each do |fr|
        if fr.kind == 'epub'
          epub_id = fr.file_set_id
        elsif fr.kind == 'pdf_ebook'
          pdf_ebook_id = fr.file_set_id
        end
      end
      @reader_ebook_id ||= (epub_id || pdf_ebook_id)
    end

    def reader_ebook
      ordered_member_docs.find { |doc| doc.id == reader_ebook_id }
    end

    def audiobook
      ordered_member_docs.find { |doc| doc.id == audiobook_id }
    end

    def audiobook?
      featured_representatives.map(&:kind).include? 'audiobook'
    end

    def audiobook_id
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'audiobook' }.first
    end

    def epub?
      featured_representatives.map(&:kind).include? 'epub'
    end

    def epub
      ordered_member_docs.find { |doc| doc.id == epub_id }
    end

    def epub_id
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'epub' }.first
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
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'webgl' }.first
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
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'database' }.first
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
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'aboutware' }.first
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
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'reviews' }.first
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
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'related' }.first
    end

    def pdf_ebook?
      featured_representatives.map(&:kind).include? 'pdf_ebook'
    end

    def pdf_ebook
      ordered_member_docs.find { |doc| doc.id == pdf_ebook_id }
    end

    def pdf_ebook_id
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'pdf_ebook' }.first
    end

    def pdf_ebook_presenter
      @pdf_ebook_presenter ||= PDFEbookPresenter.new(PDFEbook::Publication.from_path_id(UnpackService.root_path_from_noid(pdf_ebook_id, 'pdf_ebook') + ".pdf", pdf_ebook_id))
    end

    def mobi?
      featured_representatives.map(&:kind).include? 'mobi'
    end

    def mobi_id
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'mobi' }.first
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
      featured_representatives.filter_map { |fr| fr.file_set_id if fr.kind == 'peer_review' }.first
    end
  end
end
