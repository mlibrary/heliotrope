# frozen_string_literal: true

class MonographIndexer < Hyrax::WorkIndexer
  include Hyrax::IndexesBasicMetadata

  def generate_solr_document
    super.tap do |solr_doc|
      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc[Solrizer.solr_name('press_name', :symbol)] = press_name

      # Removing punctuation so that a title starting with quotes doesn't always come first
      solr_doc[Solrizer.solr_name('title', :sortable)] = object&.title&.first&.downcase&.gsub(/[^\w\s\d-]/, '')

      roleless_creators = multiline_names_minus_role('creator')
      roleless_contributors = multiline_names_minus_role('contributor')

      # fix for imported Monographs that only have contributors for whatever reason, i.e. the metadata was created...
      # outside Fulcrum and only had supposed "non-author roles" which were put in as contributors so we'll promote...
      # the first contributor to a creator for use in citations
      roleless_creators = [roleless_contributors&.shift] if roleless_creators.blank?

      solr_doc[Solrizer.solr_name('creator', :stored_searchable)] = roleless_creators
      solr_doc[Solrizer.solr_name('creator_full_name', :stored_searchable)] = roleless_creators&.first
      solr_doc[Solrizer.solr_name('creator_full_name', :facetable)] = roleless_creators&.first
      solr_doc[Solrizer.solr_name('contributor', :stored_searchable)] = roleless_contributors

      # grab previous file set order here from Solr (before they are reindexed)
      existing_fileset_order = existing_filesets
      solr_doc[Solrizer.solr_name('ordered_member_ids', :symbol)] = object.ordered_member_ids
      solr_doc[Solrizer.solr_name('representative_id', :symbol)] = object.representative_id
      trigger_fileset_reindexing(existing_fileset_order, object.ordered_member_ids)

      # grab the first fileset that is a csv and set it as the representative_manifest_id
      solr_doc[Solrizer.solr_name('representative_manifest_id', :symbol)] = existing_filesets.find { |id| ['text/csv', 'text/comma-separated-values'].include? FileSet.find(id).mime_type }
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
      # ReindexFileSetJob.perform_later(FileSet.find(id))
      FileSet.find(id).update_index
    end
  end

  def multiline_names_minus_role(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r?\n/).reject(&:blank?).map { |val| val.sub(/\s*\(.+\)$/, '').strip } : value
  end
end
