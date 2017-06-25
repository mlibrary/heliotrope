# frozen_string_literal: true

module StoresCreatorNameSeparatelyToSolr
  extend ActiveSupport::Concern

  def to_solr
    super.tap do |solr_doc|
      name = full_name
      solr_doc[Solrizer.solr_name('creator_full_name', :stored_searchable)] = name
      solr_doc[Solrizer.solr_name('creator_full_name', :facetable)] = name
    end
  end

  private

    def full_name
      joining_comma = creator_family_name.blank? || creator_given_name.blank? ? '' : ', '
      creator_family_name.to_s + joining_comma + creator_given_name.to_s
    end
end
