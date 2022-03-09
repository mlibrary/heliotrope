# frozen_string_literal: true

class MonographIndexer < Hyrax::WorkIndexer
  include Hyrax::IndexesBasicMetadata

  def generate_solr_document # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    super.tap do |solr_doc| # rubocop:disable Metrics/BlockLength
      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc[Solrizer.solr_name('press_name', :symbol)] = press_name

      # This facet is for mps and michigan only, to highlight sub-press Monographs only. I'd rather conditionally...
      # index the facetable value than put any more press-specific logic in the controllers. Could change later!
      if ['michigan', 'mps'].include? press&.parent&.subdomain
        solr_doc[Solrizer.solr_name('press_name', :facetable)] = press_name
      end

      # HELIO-3347 Indicate access levels on Publisher page, need to be able to filter by products
      solr_doc['products_lsim'] = all_product_ids_for_monograph(object)
      solr_doc[Solrizer.solr_name('product_names', :facetable)] = all_product_names_for_monograph(object)

      solr_doc[Solrizer.solr_name('title', :sortable)] = normalize_for_sort(object&.title&.first)

      # now that the exporter pulls directly from Solr, we need suitable values for creator/contributor
      solr_doc['importable_creator_ss'] = importable_names('creator')
      solr_doc['importable_contributor_ss'] = importable_names('contributor')

      roleless_creators, creator_orcids = names_and_orcids('creator')
      roleless_contributors, contributor_orcids = names_and_orcids('contributor')

      # fix for imported Monographs that only have contributors for whatever reason, i.e. the metadata was created...
      # outside Fulcrum and only had supposed "non-author roles" which were put in as contributors so we'll promote...
      # the first contributor to a creator for use in citations
      roleless_creators = [roleless_contributors&.shift] if roleless_creators.blank?

      solr_doc[Solrizer.solr_name('creator', :stored_searchable)] = roleless_creators
      solr_doc[Solrizer.solr_name('creator', :facetable)] = roleless_creators
      solr_doc[Solrizer.solr_name('creator_full_name', :stored_searchable)] = roleless_creators&.first
      solr_doc[Solrizer.solr_name('creator_full_name', :sortable)] = normalize_for_sort(roleless_creators&.first)
      solr_doc[Solrizer.solr_name('creator_orcids', :symbol)] = creator_orcids

      solr_doc[Solrizer.solr_name('contributor', :stored_searchable)] = roleless_contributors
      solr_doc[Solrizer.solr_name('contributor_orcids', :symbol)] = contributor_orcids

      # probably we'll need more substantial cleanup here, for now discard anything that isn't a number as...
      # HEB often has stuff like 'c1999' in the Publication Year (`date_created`)
      solr_doc[Solrizer.solr_name('date_created', :sortable)] = object.date_created&.first&.gsub(/[^0-9]/, '')
      # We're going to use date_published, which optionally holds the actual time the Monograph was published...
      # on Fulcrum (when it was set to public using PublishJob) to tie-break titles that have the same value...
      # indexed in date_created. Note safe navigation not needed here to prevent error, as both [].first and...
      # nil.to_i are valid, but the latter gives 0, and I think I'd rather nil so nothing is set on solr_doc
      solr_doc[Solrizer.solr_name('date_published', :sortable)] = object.date_published&.first&.to_i

      # grab previous file set order here from Solr (before they are reindexed)
      existing_fileset_order = existing_filesets
      solr_doc[Solrizer.solr_name('ordered_member_ids', :symbol)] = object.ordered_member_ids
      solr_doc[Solrizer.solr_name('representative_id', :symbol)] = object.representative_id
      trigger_fileset_reindexing(existing_fileset_order, object.ordered_member_ids)

      # 'isbn_numeric' is an isbn indexed multivalued field for finding books which is copied from 'isbn_tesim'
      #   <copyField source="isbn_tesim" dest="isbn_numeric"/>
      # the english text stored indexed multivalued field generated for the 'isbn' property a.k.a. object.isbn
      # See './app/models/monograph.rb' and './solr/config/schema.xml' for details.

      # HELIO-3709 used in the NOID API
      # Collapse whitespace in identifiers if they exist, although in practice HELIO-3712 fixes this
      solr_doc[Solrizer.solr_name('identifier', :symbol)] = object.identifier.map { |id| id.gsub(/\s/, "") }

      # Index the ToC of the monograph's epub or pdf_ebook if it has one, HELIO-3870
      solr_doc[Solrizer.solr_name('table_of_contents', :stored_searchable)] = table_of_contents(object.id)
    end
  end

  def table_of_contents(work_id)
    # prefer the epub if there is one, otherwise next in order will be pdf_ebook
    ebook_id = FeaturedRepresentative.where(work_id: work_id, kind: ['epub', 'pdf_ebook']).order(:kind).first&.file_set_id
    return [] if ebook_id.nil?
    toc = EbookTableOfContentsCache.where(noid: ebook_id).first&.toc
    return [] if toc.nil?
    JSON.parse(toc).map { |entry| entry["title"] }
  end

  def importable_names(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r?\n/).reject(&:blank?).join('; ') : value
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

  def names_and_orcids(field)
    value = object.public_send(field).first
    if value.present?
      # for now an ORCID must have a manually-entered name preceding it, a (stripped) line starting with '|' is not...
      # indexed. See spec/indexers/monograph_indexer_spec.rb for examples.
      values = value.split(/\r?\n/).reject(&:blank?).map(&:strip).reject { |val| val.start_with?('|') }
      # names and ORCIDs will strictly be parallel arrays until we (maybe) do something fancier with ORCIDs
      # nils here are not retained in Solr, hence the '' entries for names with no associated ORCID
      orcids = values.any? { |val| val.include?('|') } ? values.map { |val| val.split('|')[1]&.strip || '' } : []
      names = values.map { |val| val.split('|')[0]&.strip.sub(/|.*$/, '').sub(/\s*\(.+\)$/, '').strip }
    end
    return names.presence, orcids.presence
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

  # HELIO-3347 Indicate access levels on Publisher page
  #
  # We need to be able to filter by
  #
  #   1. All content a.k.a. no filter
  #   2. All content the current actor can access a.k.a. [-1, 0, allow read products, actor products] (see also PressSearchBuilder)
  #   3. All Open Access content a.k.a. [-1]
  #
  def all_product_ids_for_monograph(obj)
    component = Greensub::Component.find_by(noid: obj.id)
    all_prodcuts_ids = if component.blank? || component.products.empty?
                         # Default product ID for non-component monographs or components that don't belong to a product.
                         [0]
                       else
                         # Product IDs for monograph.
                         component.products.map(&:id)
                       end
    # Imaginary product ID for Open Access monographs.
    all_prodcuts_ids << -1 if /yes/i.match?(obj.open_access)
    all_prodcuts_ids.uniq.sort
  end

  def all_product_names_for_monograph(obj)
    all_product_ids = all_product_ids_for_monograph(obj)
    all_product_names = []
    all_product_names << "Open Access" if all_product_ids.include?(-1)
    all_product_names << "Unrestricted" if all_product_ids.include?(0)
    all_product_names + Greensub::Product.where(id: all_product_ids).map { |product| product.name || product.identifier }
  end
end
