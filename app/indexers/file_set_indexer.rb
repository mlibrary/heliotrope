# frozen_string_literal: true

class FileSetIndexer < Hyrax::FileSetIndexer
  attr_reader :monograph

  def generate_solr_document
    super.tap do |solr_doc|
      # Removing punctuation so that a title starting with quotes doesn't always come first
      solr_doc[Solrizer.solr_name('title', :sortable)] = object&.title&.first&.downcase&.gsub(/[^\w\s\d-]/, '')
      solr_doc[Solrizer.solr_name('resource_type', :sortable)] = object&.resource_type&.first

      # now that the exporter pulls directly from Solr, we need suitable values for creator/contributor
      solr_doc['importable_creator_ss'] = importable_names('creator')
      solr_doc['importable_contributor_ss'] = importable_names('contributor')

      roleless_creators = multiline_names_minus_role('creator')
      solr_doc[Solrizer.solr_name('creator', :stored_searchable)] = roleless_creators
      solr_doc[Solrizer.solr_name('creator', :facetable)] = roleless_creators
      solr_doc[Solrizer.solr_name('creator_full_name', :stored_searchable)] = roleless_creators&.first
      primary_creator_role = first_creator_roles
      solr_doc[Solrizer.solr_name('primary_creator_role', :stored_searchable)] = primary_creator_role
      solr_doc[Solrizer.solr_name('primary_creator_role', :facetable)] = primary_creator_role
      solr_doc[Solrizer.solr_name('contributor', :stored_searchable)] = multiline_contributors # include roles

      # Extra technical metadata we need to index
      # These are apparently not necessarily integers all the time, so index them as symbols
      index_technical_metadata(solr_doc, object.original_file) if object.original_file.present?

      # Neither we nor Hyrax have FileSets attached to more than one Monograph/Work and we haven't had...
      # "intermediate" Works (a.k.a. "Sections") in a really long time. So grab the one and only parent *once* here.
      @monograph ||= object.in_works.first

      index_monograph_metadata(solr_doc) if @monograph.present?
      index_monograph_position(solr_doc) if @monograph.present?
      if object.sort_date.present?
        solr_doc[Solrizer.solr_name('search_year', :sortable)] = object.sort_date[0, 4]
        solr_doc[Solrizer.solr_name('search_year', :facetable)] = object.sort_date[0, 4]
      end

      index_extra_json_properties(solr_doc) if object.extra_json_properties.present?
    end
  end

  def importable_names(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r?\n/).reject(&:blank?).join('; ') : value
  end

  def multiline_names_minus_role(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r?\n/).reject(&:blank?).map { |val| val.sub(/\s*\(.+\)$/, '').strip } : value
  end

  def multiline_contributors
    # any role in parenthesis will persist in Solr for contributors, as we've always done
    value = object.contributor.first
    value.present? ? value.split(/\r?\n/).reject(&:blank?).map(&:strip) : value
  end

  def first_creator_roles
    value = object.creator.first
    value.present? ? Array.wrap(value[/\(([^()]*)\)/]&.gsub(/\(|\)/, '')&.split(',')&.map(&:strip)&.map(&:downcase)) : value
  end

  def index_technical_metadata(solr_doc, orig)
    solr_doc[Solrizer.solr_name('duration', :symbol)] = orig.duration.first if orig.duration.present?
    solr_doc[Solrizer.solr_name('sample_rate', :symbol)] = orig.sample_rate if orig.sample_rate.present?
    solr_doc[Solrizer.solr_name('original_checksum', :symbol)] = orig.original_checksum if orig.original_checksum.present?
    solr_doc[Solrizer.solr_name('original_name', :stored_searchable)] = orig.original_name if orig.original_name.present?
  end

  # Make sure the asset is aware of its monograph
  def index_monograph_metadata(solr_doc)
    solr_doc[Solrizer.solr_name('monograph_id', :symbol)] = @monograph.id
  end

  def index_monograph_position(solr_doc)
    # avoid nil errors here on first pass of reindex_everything if parent not yet indexed
    return if @monograph.blank?
    fileset_order = @monograph.ordered_member_ids
    solr_doc['monograph_position_isi'] = fileset_order.index(object.id) if fileset_order.present?
  end

  # We are deciding to put arbitrary json data into this field based on what kind of FileSet this is.
  # Instead of creating child nested works, or just adding a while bunch of fields to FileSets.
  # So there's no schema for this. Be careful what you stuff into it I guess.
  # See HELIO-2912
  def index_extra_json_properties(solr_doc)
    JSON.parse(object.extra_json_properties).each do |k, v|
      # everything is shallow and gets _tesim (until we need them not to)
      solr_doc["#{k}_tesim"] = v if v.present?
    end
  end
end
