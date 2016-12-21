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
             to: :solr_document

    def section_docs
      return @section_docs if @section_docs
      @section_docs = ordered_member_docs.select { |doc| doc['has_model_ssim'] == ['Section'].freeze }
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

    private

      def ordered_file_sets_ids
        return @ordered_file_sets_ids if @ordered_file_sets_ids
        file_sets_ids = []
        ordered_member_docs.each do |doc|
          if doc['has_model_ssim'] == ['Section'].freeze
            # Danger, Will Robinson! the ordered list is stored in reverse order.
            doc['ordered_member_ids_ssim'].reverse_each do |file_sets_id|
              file_sets_ids.append file_sets_id
            end unless doc['ordered_member_ids_ssim'].nil?
          elsif doc['has_model_ssim'] == ['FileSet'].freeze && doc.id != representative_id
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
  end
end
