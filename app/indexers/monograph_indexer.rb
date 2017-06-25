# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Monograph`
class MonographIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  def generate_solr_document
    super.tap do |solr_doc|
      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc[Solrizer.solr_name('press_name', :symbol)] = press_name

      solr_doc[Solrizer.solr_name('primary_editor_full_name', :stored_searchable)] = editor_full_name
      solr_doc[Solrizer.solr_name('primary_editor_full_name', :facetable)] = editor_full_name

      # grab previous file set order here from Solr (before they are reindexed)
      existing_fileset_order = existing_filesets
      solr_doc[Solrizer.solr_name('ordered_member_ids', :symbol)] = object.ordered_member_ids
      solr_doc[Solrizer.solr_name('representative_id', :symbol)] = object.representative_id
      solr_doc[Solrizer.solr_name('representative_epub_id', :symbol)] = existing_fileset_order.find { |id| ['application/epub+zip'].include? FileSet.find(id).mime_type }
      trigger_fileset_reindexing(existing_fileset_order, object.ordered_member_ids)
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

  def editor_full_name
    # This is the same as StoresCreatorNameSeparately#last_name
    # but I'm not sure why we're even doing this: "Lastname, Firstname"?
    joining_comma = object.primary_editor_family_name.blank? || object.primary_editor_given_name.blank? ? '' : ', '
    object.primary_editor_family_name.to_s + joining_comma + object.primary_editor_given_name.to_s
  end
end
