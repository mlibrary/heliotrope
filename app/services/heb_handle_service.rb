# frozen_string_literal: true

class HebHandleService
  delegate :heb_ids_from_identifier, to: :class

  def initialize(noid_or_mono_doc)
    # Tying this service into the nightly-run HandleJob only (and not model callbacks). So the kludge here of...
    # "SolrHit *or* NOID" initialization saves an extra Solr query per HEB Monograph in that usage, while leaving...
    # the NOID initialization option might be useful for testing/specs and console sanity checks.
    if noid_or_mono_doc.is_a?(ActiveFedora::SolrHit)
      @noid = noid_or_mono_doc.id
      @mono_doc = noid_or_mono_doc
    else
      @noid = noid_or_mono_doc
      @mono_doc = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:heb AND +id:#{noid_or_mono_doc}", rows: 1)&.first
    end

    @heb_ids = heb_ids_from_identifier(@mono_doc['identifier_tesim']) || []
  end

  def self.heb_ids_from_identifier(identifier)
    heb_ids_identifier_entry = identifier&.find { |i| i.strip.downcase[/^heb_id:\s*heb[0-9]{5}.[0-9]{4}.[0-9]{3}/] }&.strip&.downcase
    return nil if heb_ids_identifier_entry.blank?
    heb_ids_identifier_entry = heb_ids_identifier_entry.gsub(/heb_id:\s*heb/, 'heb')
    heb_ids_identifier_entry.scan(/heb[0-9]{5}.[0-9]{4}.[0-9]{3}/)
  end

  # Not used right now, but _should_ be used at some stage, as a sanity check. There is a TODO below, but such a...
  # check could instead happen elsewhere in metadata checks/rules.
  def find_duplicate_book_ids
    return [] if @heb_ids.blank?
    # no other book should have the HEB IDs present in this Monograph's identifier `heb_id:...` entry
    # any heb Monograph *other* than the one with NOID monograph_id using any of these full-book HEB IDs?
    query = "+has_model_ssim:Monograph AND +press_sim:heb AND -id:#{@noid} AND +identifier_tesim:(#{@heb_ids.join(',')})"
    ActiveFedora::SolrService.query(query, rows: 100_000)
  end

  # Down the road, if all is well with the HEB handles being created/deleted nightly we can refactor this method to...
  # only hit Solr once for all of the HEB Monographs, for that nightly usage at least.
  def title_level_handles
    heb_title_ids = @heb_ids.map { |heb_full_book_id| heb_full_book_id[0, 8] }

    title_level_handles = {}

    heb_title_ids.each do |heb_title_id|
      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:heb AND -id:#{@noid} AND +identifier_tesim:#{heb_title_id}*", rows: 100_000)

      # If a title has multiple Monographs we will point the title-level handle to a Blacklight search, e.g.:
      # '2027/heb04045' --> 'https://www.fulcrum.org/heb?q=heb04045*'
      # Otherwise we will simply point it to the one extant HEB Monograph, e.g.:
      # '2027/heb12345' --> 'https://www.fulcrum.org/concern/monographs/999999999'
      if docs.count > 0
        # Adding the q parameter using the helper seems inevitably to URL-escape the asterisk. Just concatenate it.
        title_level_handles["2027/#{heb_title_id}"] = Rails.application.routes.url_helpers.press_catalog_url('heb') + "?q=#{heb_title_id}*"
      else
        title_level_handles["2027/#{heb_title_id}"] = Rails.application.routes.url_helpers.hyrax_monograph_url(@noid)
      end
    end

    title_level_handles
  end

  # these are the "full HEB ID" handles, they always point to the Monograph in whose `identifier` field they are found
  def book_level_handles
    book_level_handles = {}

    @heb_ids.each do |heb_book_id|
      book_level_handles["2027/#{heb_book_id}"] = Rails.application.routes.url_helpers.hyrax_monograph_url(@noid)
    end

    book_level_handles
  end

  def handles
    # TODO: step 1 will be to run `find_duplicate_book_ids(heb_ids)` and message (email fulcrum-dev??) if any are found
    book_level_handles.merge(title_level_handles)
  end
end
