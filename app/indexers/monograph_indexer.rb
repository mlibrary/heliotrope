# frozen_string_literal: true

class MonographIndexer < Hyrax::WorkIndexer
  include Hyrax::IndexesBasicMetadata

  def generate_solr_document # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    super.tap do |solr_doc| # rubocop:disable Metrics/BlockLength
      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc['press_name_ssim'] = press_name

      # This facet is for mps and michigan only, to highlight sub-press Monographs only. I'd rather conditionally...
      # index the facetable value than put any more press-specific logic in the controllers. Could change later!
      if ['michigan', 'mps'].include? press&.parent&.subdomain
        solr_doc['press_name_sim'] = press_name
      end

      # HELIO-3347 Indicate access levels on Publisher page, need to be able to filter by products
      solr_doc['products_lsim'] = all_product_ids_for_monograph(object)
      solr_doc['product_names_sim'] = all_product_names_for_monograph(object)

      solr_doc['title_si'] = normalize_for_sort(object&.title&.first)

      roleless_creators, creator_orcids = names_and_orcids('creator')
      roleless_contributors, contributor_orcids = names_and_orcids('contributor')

      # fix for imported Monographs that only have contributors for whatever reason, i.e. the metadata was created...
      # outside Fulcrum and only had supposed "non-author roles" which were put in as contributors so we'll promote...
      # the first contributor to a creator for use in citations
      roleless_creators = [roleless_contributors&.shift] if roleless_creators.blank?

      solr_doc['creator_tesim'] = roleless_creators
      solr_doc['creator_sim'] = roleless_creators
      solr_doc['creator_full_name_tesim'] = roleless_creators&.first
      solr_doc['creator_full_name_si'] = normalize_for_sort(roleless_creators&.first)
      solr_doc['creator_orcids_ssim'] = creator_orcids

      solr_doc['contributor_tesim'] = roleless_contributors
      solr_doc['contributor_orcids_ssim'] = contributor_orcids

      # index authorship fields as they are stored in Fedora, for fast access use, e.g. console or ScholarlyiQ rake tasks
      solr_doc['creator_ss'] = importable_backup_authorship_value('creator')
      solr_doc['contributor_ss'] = importable_backup_authorship_value('contributor')

      # `date_created` is our citation pub date. We also use it for "year asc/desc" Blacklight results sorting.
      # Probably we'll need more substantial cleanup here, for now discard anything that isn't a 4-digit number as...
      # HEB often has stuff like 'c1999' in the Publication Year (`date_created`)
      citation_year_digits = object.date_created&.first&.gsub(/[^0-9]/, '') || ''
      solr_doc['date_created_si'] = citation_year_digits[0, 4] if citation_year_digits.length >= 4

      # We're going to use date_published, which optionally holds the actual time the Monograph was published...
      # on Fulcrum (when it was set to public using PublishJob) to tie-break titles that have the same value...
      # indexed in date_created. Note safe navigation not needed here to prevent error, as both [].first and...
      # nil.to_i are valid, but the latter gives 0, and I think I'd rather nil so nothing is set on solr_doc
      # 20230120: For the new conditional see HELIO-4397, and the follow-up HELIO-4410, i.e. defer to the Hyrax...
      # actor stack mod time, `date_uploaded`, if `date_published` was never set.
      if object.date_published.present?
        solr_doc['date_published_si'] = object.date_published&.first&.to_i
        # super handles the `date_published_dtsim` value when a value exists in Fedora
      elsif object.visibility == 'open'
        # Here we index historical blank `date_published` values with `date_uploaded` to aid in results sorting.
        # No blank date_published values should exist in future thanks to HELIO-4402.
        # Note also `date_uploaded` is aliased to the Fedora-level `create_date` in...
        # our models, and so it will *always* be set.
        solr_doc['date_published_si'] = object.date_uploaded&.to_i
        # set the `date_published_dtsim` value too so that we can display the deferred value where required.
        solr_doc['date_published_dtsim'] = [object.date_uploaded]
      end

      # grab previous file set order and cover_id here from Solr (before they are reindexed)
      existing_monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{object.id}", fl: ['ordered_member_ids_ssim', 'representative_id_ssim'], rows: 1)[0]

      existing_fileset_order = existing_filesets(existing_monograph_doc)
      solr_doc['ordered_member_ids_ssim'] = object.ordered_member_ids
      solr_doc['representative_id_ssim'] = object.representative_id
      trigger_fileset_reindexing(existing_fileset_order, object.ordered_member_ids)

      # making sure that `monograph_representative_bsi` gets set or removed if/when covers change
      if existing_monograph_doc.present? && existing_monograph_doc['representative_id_ssim']&.first != object.representative_id
        UpdateIndexJob.perform_later(existing_monograph_doc['representative_id_ssim']&.first) if existing_monograph_doc['representative_id_ssim'].present?
        UpdateIndexJob.perform_later(object.representative_id)
      end

      # 'isbn_numeric' is an isbn indexed multivalued field for finding books which is copied from 'isbn_tesim'
      #   <copyField source="isbn_tesim" dest="isbn_numeric"/>
      # the english text stored indexed multivalued field generated for the 'isbn' property a.k.a. object.isbn
      # See './app/models/monograph.rb' and './solr/config/schema.xml' for details.

      # a clean identifier value with no whitespace and no preceding namespace like `bar_number:` or `heb_id:`
      solr_doc['identifier_ssim'] = object.identifier.map { |id| id.gsub(/\s/, "").gsub(/^.+:/, "") }

      # Index the ToC of the monograph's epub or pdf_ebook if it has one, HELIO-3870
      solr_doc['table_of_contents_tesim'] = table_of_contents(object.id)

      # HELIO-2428 index the "full" doi url if there's a doi
      solr_doc['doi_url_ssim'] = "https://doi.org/" + object.doi if object.doi.present?

      # HELIO-4125 - Extract EPUB metadata on ingest and store in Solr
      maybe_index_accessibility_metadata(solr_doc)
    end
  end

  def importable_backup_authorship_value(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r\n?|\n/).map(&:strip).reject(&:blank?).join('; ') : value
  end

  def table_of_contents(work_id)
    # prefer the epub if there is one, otherwise next in order will be pdf_ebook
    ebook_id = FeaturedRepresentative.where(work_id: work_id, kind: ['epub', 'pdf_ebook']).order(:kind).first&.file_set_id
    return [] if ebook_id.nil?
    toc = EbookTableOfContentsCache.where(noid: ebook_id).first&.toc
    return [] if toc.nil?
    JSON.parse(toc).map { |entry| entry["title"] }
  end

  def existing_filesets(existing_monograph_doc)
    order = existing_monograph_doc.blank? ? [] : existing_monograph_doc['ordered_member_ids_ssim']
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
      values = value.split(/\r\n?|\n/).reject(&:blank?).map(&:strip).reject { |val| val.start_with?('|') }
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

  def maybe_index_accessibility_metadata(solr_doc)
    epub_fr = FeaturedRepresentative.where(work_id: object.id, kind: 'epub')&.first
    if epub_fr.present?
      EpubAccessibilityMetadataIndexingService.index(epub_fr.file_set_id, solr_doc)
    else
      pdf_ebook_fr = FeaturedRepresentative.where(work_id: object.id, kind: 'pdf_ebook')&.first
      if pdf_ebook_fr.present?
        # although `EpubAccessibilityMetadataPresenter.epub_a11y_screen_reader_friendly()` will always show this...
        # value for Screen Reader Friendly, even if it's missing, as will always be the case for PDFs (for now at...
        # least), we still need to index it for use in facets.
        solr_doc['epub_a11y_screen_reader_friendly_ssi'] = 'unknown'
      end
    end
  end
end
