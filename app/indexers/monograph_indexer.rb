class MonographIndexer < CurationConcerns::WorkIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('ordered_member_ids', :symbol)] = object.ordered_member_ids

      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc[Solrizer.solr_name('press_name', :symbol)] = press_name
    end
  end
end
