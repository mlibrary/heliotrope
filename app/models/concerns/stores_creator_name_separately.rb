module StoresCreatorNameSeparately
  extend ActiveSupport::Concern

  included do
    # The primary creator's family name and given name are
    # stored in separate properties in the fedora record.
    property :creator_family_name, predicate: ::RDF::Vocab::FOAF.family_name, multiple: false do |index|
      index.as :stored_searchable
    end

    property :creator_given_name, predicate: ::RDF::Vocab::FOAF.givenname, multiple: false do |index|
      index.as :stored_searchable
    end
  end

  # Index the primary creator's full name in solr for faceting,
  # searching, and display.
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
