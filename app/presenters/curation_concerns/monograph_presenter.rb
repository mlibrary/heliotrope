module CurationConcerns
  class MonographPresenter < WorkShowPresenter
    def section_docs
      return @section_docs if @section_docs
      @section_docs = member_docs.select { |doc| doc['active_fedora_model_ssi'] == 'Section'.freeze }
    end

    private

      def member_docs
        return @member_docs if @member_docs
        ids = solr_document[Solrizer.solr_name('member_ids', :symbol)]
        @member_docs = if ids.blank?
                         []
                       else
                         ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}").map { |res| SolrDocument.new(res) }
                       end
      end
  end
end
