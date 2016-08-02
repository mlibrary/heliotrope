module CurationConcerns
  class MonographPresenter < WorkShowPresenter
    include ActionView::Helpers::UrlHelper

    delegate :title, :date_created, :date_modified, :date_uploaded,
             :description, :creator, :editor, :contributor, :subject,
             :publisher, :date_published, :language, :isbn, :isbn_softcover,
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

    private

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
