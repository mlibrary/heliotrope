# frozen_string_literal: true

class MonographIndexer < Hyrax::WorkIndexer
  include Hyrax::IndexesBasicMetadata

  def generate_solr_document
    super.tap do |solr_doc|
      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc[Solrizer.solr_name('press_name', :symbol)] = press_name

      solr_doc[Solrizer.solr_name('title', :sortable)] = normalize_for_sort(object&.title&.first)
      roleless_creators = multiline_names_minus_role('creator')
      roleless_contributors = multiline_names_minus_role('contributor')

      # fix for imported Monographs that only have contributors for whatever reason, i.e. the metadata was created...
      # outside Fulcrum and only had supposed "non-author roles" which were put in as contributors so we'll promote...
      # the first contributor to a creator for use in citations
      roleless_creators = [roleless_contributors&.shift] if roleless_creators.blank?

      solr_doc[Solrizer.solr_name('creator', :stored_searchable)] = roleless_creators
      solr_doc[Solrizer.solr_name('creator', :facetable)] = roleless_creators
      solr_doc[Solrizer.solr_name('creator_full_name', :stored_searchable)] = roleless_creators&.first
      solr_doc[Solrizer.solr_name('creator_full_name', :sortable)] = normalize_for_sort(roleless_creators&.first)

      solr_doc[Solrizer.solr_name('contributor', :stored_searchable)] = roleless_contributors
      # probably we'll need more substantial cleanup here, for now discard anything that isn't a number as...
      # HEB often has stuff like 'c1999' in the Publication Year (`date_created`)
      solr_doc[Solrizer.solr_name('date_created', :sortable)] = object.date_created&.first&.gsub(/[^0-9]/, '')

      # grab previous file set order here from Solr (before they are reindexed)
      existing_fileset_order = existing_filesets
      solr_doc[Solrizer.solr_name('ordered_member_ids', :symbol)] = object.ordered_member_ids
      solr_doc[Solrizer.solr_name('representative_id', :symbol)] = object.representative_id
      trigger_fileset_reindexing(existing_fileset_order, object.ordered_member_ids)

      # 'isbn_numeric' is an isbn indexed multivalued field for finding books which is copied from 'isbn_tesim'
      #   <copyField source="isbn_tesim" dest="isbn_numeric"/>
      # the english text stored indexed multivalued field generated for the 'isbn' property a.k.a. object.isbn
      # See './app/models/monograph.rb' and './solr/config/schema.xml' for details.
      # Note: Since this happens server side it may not be possible to write a spec for this field.
    end
  end

  def existing_filesets
    existing_monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{object.id}", rows: 1)
    order = existing_monograph_doc.blank? ? [] : existing_monograph_doc[0][Solrizer.solr_name('ordered_member_ids', :symbol)]
    order || []
  end

  def trigger_fileset_reindexing(existing_fileset_order, new_fileset_order)
    new_fileset_order.each_with_index do |id, new_index|
      former_position = existing_fileset_order.index(id)
      next unless former_position && former_position != new_index
      UpdateIndexJob.perform_later(id)
    end
  end

  def multiline_names_minus_role(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r?\n/).reject(&:blank?).map { |val| val.sub(/\s*\(.+\)$/, '').strip } : value
  end

  def normalize_for_sort(value)
    # transliterate() can't handle nil
    value ||= ''
    # Removing punctuation so that, e.g., a value starting with quotes doesn't always come first
    # transliterate will take care of mapping accented chars to an ASCII equivalent
    value = ActiveSupport::Inflector.transliterate(value).downcase.gsub(/[^\w\s\d-]/, '')
    # return nil to ensure removal of Solr doc value if appropriate
    value.presence
  end
end
