# frozen_string_literal: true

class RepositoryPresenter < ApplicationPresenter
  def policy_ids
    Checkpoint::DB::Permit.dataset.map(&:id)
  end

  def product_ids
    Product.all.map(&:id)
  end

  def component_ids
    Component.all.map(&:id)
  end

  def lessee_ids
    Lessee.all.map(&:id)
  end

  def institution_ids
    Institution.all.map(&:id)
  end

  def publisher_ids
    Press.all.map(&:id)
  end

  def monograph_ids(publisher = nil)
    docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph", rows: 10_000)
    ids = []
    docs.each do |doc|
      if publisher.nil?
        ids << doc['id']
      elsif doc['press_tesim']&.first == publisher.subdomain
        ids << doc['id']
      end
    end
    ids
  end

  def asset_ids(publisher = nil)
    asset_ids = []
    monograph_ids(publisher).each do |monograph_id|
      monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{monograph_id}", rows: 1)
      if monograph_doc.present?
        asset_ids += monograph_doc[0][Solrizer.solr_name('ordered_member_ids', :symbol)] || []
      end
    end
    asset_ids
  end

  def user_ids(publisher = nil)
    return User.all.map(&:id) if publisher.nil?
    User.joins("INNER JOIN roles ON roles.user_id = users.id AND roles.resource_id = #{publisher.id} AND roles.resource_type = 'Press'").map(&:id)
  end
end
