class MonographPresenter < ::CurationConcerns::WorkShowPresenter
  delegate :title, :date_created, :date_modified, :date_uploaded, :description,
           :creator, :editor, :contributor, :subject, :publisher, :date, :language,
           :isbn, :copyright_holder, :buy_url, :embargo_release_date,
           :lease_expiration_date, :rights, to: :solr_document

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
