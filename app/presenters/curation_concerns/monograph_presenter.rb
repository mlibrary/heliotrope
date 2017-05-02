module CurationConcerns
  class MonographPresenter < WorkShowPresenter
    include TitlePresenter
    include AnalyticsPresenter
    include OpenUrlPresenter
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

    # ASSUMPTION: Each FileSet record has only 1 section_title.
    # If section_title has more than 1 value, the order of the
    # titles is not guaranteed (because multi-value fields are
    # unordered in fedora).  See the spec file for interesting
    # test cases.
    def ordered_section_titles
      ordered_member_docs.flat_map(&:section_title).uniq
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
      !editors.blank?
    end

    def subdomain
      Array(solr_document['press_tesim']).first
    end

    def press
      Array(solr_document['press_name_ssim']).first
    end

    def press_logo
      Press.find_by(subdomain: subdomain).logo_path
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
        if doc['has_model_ssim'] == ['FileSet'].freeze && doc.id != representative_id
          file_sets_ids.append doc.id
        end
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
          h[res['id']] = SolrDocument.new(res)
        end

        @ordered_member_docs = ids.map { |id| docs_hash[id] }
      end
    end

    def buy_url?
      !solr_document.buy_url.blank?
    end

    def buy_url
      solr_document.buy_url.first if buy_url?
    end

    def epub?
      ordered_member_docs.any? { |doc| ['application/epub+zip'].include? doc.mime_type unless doc.nil? }
    end

    def epub
      ordered_member_docs.find { |doc| ['application/epub+zip'].include? doc.mime_type unless doc.nil? }
    end

    # This overrides CC 1.6.2's work_show_presenter.rb which is recursive.
    # Because our FileSets also have respresentative_presenters (I guess that's not normal?)
    # this recursive call from Work -> Arbitrary Nesting of Works -> FileSet never ends.
    # Our PCDM model currently only has Work -> FileSet so this this non-recursive approach should be fine
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||= CurationConcerns::PresenterFactory.build_presenters([representative_id], CurationConcerns::FileSetPresenter, current_ability).first
    end
  end
end
