class RepositoryPresenter < ApplicationPresenter
  def publisher_ids
    Press.all.map(&:id)
  end

  def monograph_ids(publisher = nil)
    query = {}
    query[Solrizer.solr_name('has_model', :symbol)] = 'Monograph'
    # query[Solrizer.solr_name('press', :symbol)] = publisher.subdomain unless publisher.nil?
    query[:press_tesim] = publisher.subdomain unless publisher.nil?
    ActiveFedora::Base.where(query).map(&:id)
  end

  def asset_ids(publisher = nil)
    query = {}
    query[Solrizer.solr_name('has_model', :symbol)] = 'Monograph'
    # query[Solrizer.solr_name('press', :symbol)] = publisher.subdomain unless publisher.nil?
    query[:press_tesim] = publisher.subdomain unless publisher.nil?
    monographs = ActiveFedora::Base.where(query)
    asset_ids = []
    monographs.each do |monograph|
      monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{monograph.id}")
      asset_ids += monograph_doc.blank? ? [] : monograph_doc[0][Solrizer.solr_name('ordered_member_ids', :symbol)]
    end
    asset_ids
  end

  def user_ids(publisher = nil)
    return User.all.map(&:id) if publisher.nil?
    User.joins("INNER JOIN roles ON roles.user_id = users.id AND roles.resource_id = #{publisher.id} AND roles.resource_type = 'Press'").map(&:id)
  end
end
