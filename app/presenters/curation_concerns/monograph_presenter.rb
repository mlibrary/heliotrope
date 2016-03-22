module CurationConcerns
  class MonographPresenter < WorkShowPresenter
    delegate :title, :date_created, :date_modified, :date_uploaded,
             :description, :creator, :editor, :contributor, :subject,
             :publisher, :date_published, :language, :isbn, :copyright_holder,
             :buy_url, :embargo_release_date, :lease_expiration_date, :rights,
             to: :solr_document

    def section_docs
      return @section_docs if @section_docs
      @section_docs = ordered_member_docs.select { |doc| doc['active_fedora_model_ssi'] == 'Section'.freeze }
    end

    private

      def ordered_member_docs
        return @ordered_member_docs if @ordered_member_docs

        ids = Array(solr_document[Solrizer.solr_name('ordered_member_ids', :symbol)])

        if ids.blank?
          @ordered_member_docs = []
          return @ordered_member_docs
        else
          query_results = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}")

          docs_hash = query_results.each_with_object({}) do |res, h|
            h[res['id']] = SolrDocument.new(res)
          end

          @ordered_member_docs = ids.map { |id| docs_hash[id] }
        end
      end
  end
end
