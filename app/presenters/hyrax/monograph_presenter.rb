# frozen_string_literal: true

module Hyrax
  class MonographPresenter < WorkShowPresenter
    include CCAnalyticsPresenter
    include ISBNPresenter
    include OpenUrlPresenter
    include TitlePresenter
    include ActionView::Helpers::UrlHelper

    delegate :date_created, :date_modified, :date_uploaded,
             :description, :creator, :editor, :contributor, :subject,
             :publisher, :date_published, :language, :isbn, :isbn_paper,
             :isbn_ebook, :copyright_holder, :buy_url, :embargo_release_date,
             :lease_expiration_date, :rights, :creator_full_name,
             :creator_given_name, :creator_family_name,
             :primary_editor_family_name, :primary_editor_given_name,
             :primary_editor_full_name,
             to: :solr_document

    def ordered_section_titles
      # FileSets store their section_title as ActiveTriples::Relation, which does not preserve order.
      # As a result they can't be relied on to give the correct order for their own sections, or sections as a whole.
      # For this reason, we're adding section_titles to the monograph, where all sections are entered manually, giving
      # canonical order (and later spelling etc) for FileSet sections.
      # However, fileset_section_titles will make a useful fallback.
      fileset_section_titles = ordered_member_docs.flat_map(&:section_title).uniq
      manual_monograph_section_titles = solr_document.section_titles
      if manual_monograph_section_titles.present?
        if fileset_section_titles.count != manual_monograph_section_titles.count
          Rails.logger.warn("Monograph #{id} has a section_titles count not matching its FileSets' unique section_titles")
        end
        manual_monograph_section_titles
      else
        fileset_section_titles
      end
    end

    def display_section_titles(section_titles_in)
      section_titles_out = []
      ordered_section_titles.each do |ordered_title|
        section_titles_in.each { |title| section_titles_out << ordered_title if title == ordered_title }
      end
      section_titles_out.blank? ? section_titles_in.to_sentence : section_titles_out.to_sentence
    end

    def sub_brand_links
      press = Press.where(subdomain: solr_document[:press_tesim]).first
      return nil unless press

      Array(solr_document[:sub_brand_ssim]).map do |id|
        sub_brand = SubBrand.find(id) if SubBrand.exists?(id)
        next unless sub_brand
        link_to(sub_brand.title, Rails.application.routes.url_helpers.press_sub_brand_path(press, id))
      end.compact
    end

    def editors
      ["#{primary_editor_given_name} #{primary_editor_family_name}", editor].flatten.to_sentence
    end

    def editors?
      editors.present?
    end

    def authors
      ["#{creator_given_name} #{creator_family_name}", contributor].flatten.to_sentence
    end

    def authors?
      authors.present?
    end

    def subdomain
      Array(solr_document['press_tesim']).first
    end

    def press
      Array(solr_document['press_name_ssim']).first
    end

    def press_url
      Press.find_by(subdomain: subdomain).press_url
    end

    def previous_file_sets_id?(file_sets_id)
      return false unless ordered_file_sets_ids.include? file_sets_id
      ordered_file_sets_ids.first != file_sets_id
    end

    def previous_file_sets_id(file_sets_id)
      return nil unless previous_file_sets_id? file_sets_id
      ordered_file_sets_ids[(ordered_file_sets_ids.find_index(file_sets_id) - 1)]
    end

    def next_file_sets_id?(file_sets_id)
      return false unless ordered_file_sets_ids.include? file_sets_id
      ordered_file_sets_ids.last != file_sets_id
    end

    def next_file_sets_id(file_sets_id)
      return nil unless next_file_sets_id? file_sets_id
      ordered_file_sets_ids[(ordered_file_sets_ids.find_index(file_sets_id) + 1)]
    end

    def pageviews
      pageviews_by_ids(ordered_file_sets_ids << id)
    end

    def ordered_file_sets_ids
      return @ordered_file_sets_ids if @ordered_file_sets_ids
      file_sets_ids = []
      ordered_member_docs.each do |doc|
        next if doc['has_model_ssim'] != ['FileSet'].freeze
        next if doc.id == solr_document.representative_id
        next if doc.id == solr_document.representative_epub_id
        next if doc.id == solr_document.representative_manifest_id
        file_sets_ids.append doc.id
      end
      @ordered_file_sets_ids = file_sets_ids
    end

    def ordered_member_docs
      return @ordered_member_docs if @ordered_member_docs

      ids = Array(solr_document[Solrizer.solr_name('ordered_member_ids', :symbol)])

      if ids.blank?
        @ordered_member_docs = []
        return @ordered_member_docs
      else
        query_results = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}", rows: ids.count)

        docs_hash = query_results.each_with_object({}) do |res, h|
          h[res['id']] = ::SolrDocument.new(res)
        end

        @ordered_member_docs = ids.map { |id| docs_hash[id] }
      end
    end

    def buy_url?
      solr_document.buy_url.present?
    end

    def buy_url
      solr_document.buy_url.first if buy_url?
    end

    def epub?
      solr_document.representative_epub_id.present?
    end

    def epub
      ordered_member_docs.find { |doc| doc.id == solr_document.representative_epub_id } if epub?
    end

    def epub_id
      solr_document.representative_epub_id if epub?
    end

    def epub_presenter
      FactoryService.e_pub_publication(solr_document.representative_epub_id).presenter
    end

    def manifest?
      solr_document.representative_manifest_id.present?
    end

    def manifest_id
      solr_document.representative_manifest_id if manifest?
    end

    def manifest
      ordered_member_docs.find { |doc| doc.id == solr_document.representative_manifest_id } if manifest?
    end

    def monograph_coins_title?
      return false unless defined? monograph_coins_title
      monograph_coins_title.present?
    end

    # This overrides CC 1.6.2's work_show_presenter.rb which is recursive.
    # Because our FileSets also have respresentative_presenters (I guess that's not normal?)
    # this recursive call from Work -> Arbitrary Nesting of Works -> FileSet never ends.
    # Our PCDM model currently only has Work -> FileSet so this this non-recursive approach should be fine
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||= Hyrax::PresenterFactory.build_presenters([representative_id], Hyrax::FileSetPresenter, current_ability).first
    end

    def representative_alt_text?
      solr_document.representative_id.present?
    end

    # Alt text for cover page/thumbnail. Defaults to first title if not found.
    def representative_alt_text
      rep = representative_presenter
      rep.nil? || rep.alt_text.empty? ? solr_document.title.first : rep.alt_text.first
    end

    def assets?
      ordered_file_sets_ids.present?
    end
  end
end
