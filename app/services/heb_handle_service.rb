# frozen_string_literal: true

class HebHandleService
  delegate :heb_ids_from_identifier, to: :class

  def initialize(heb_monograph_noid)
    @noid = heb_monograph_noid
    @mono_doc = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:heb AND +id:#{heb_monograph_noid}", rows: 1)&.first
    @heb_ids = heb_ids_from_identifier(@mono_doc['identifier_tesim'])
  end

  def self.heb_ids_from_identifier(identifier)
    heb_ids_identifier_entry = identifier&.find { |i| i.strip.downcase[/^heb_id:\s*heb[0-9]{5}.[0-9]{4}.[0-9]{3}/] }&.strip&.downcase
    return nil if heb_ids_identifier_entry.blank?
    heb_ids_identifier_entry = heb_ids_identifier_entry.gsub(/heb_id:\s*heb/, 'heb')
    heb_ids_identifier_entry.scan(/heb[0-9]{5}.[0-9]{4}.[0-9]{3}/)
  end

  def find_duplicate_book_ids
    # no other book should have the HEB IDs present in this Monograph's identifier `heb_id:...` entry
    # any heb Monograph *other* than the one with NOID monograph_id using any of these full-book HEB IDs?
    query = "+has_model_ssim:Monograph AND +press_sim:heb AND -id:#{@noid} AND +identifier_tesim:(#{@heb_ids.join(',')})"
    ActiveFedora::SolrService.query(query, rows: 100_000)
  end

  def title_level_handles
    heb_title_ids = @heb_ids.map { |heb_full_book_id| heb_full_book_id[0, 8] }

    title_level_handles = {}

    heb_title_ids.each do |heb_title_id|
      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:heb AND -id:#{@noid} AND +identifier_tesim:#{heb_title_id}*", rows: 100_000)
      if docs.count > 0
        # Adding the q parameter using the helper semms inevitably to URL-escape the asterisk. Just concatenate it.
        title_level_handles["https://hdl.handle.net/2027/#{heb_title_id}"] = Rails.application.routes.url_helpers.press_catalog_url('heb') + "?q=#{heb_title_id}*"
        # TODO: at this point other Monographs found (with matching title-level handles) need to have HebHandleService run against them,...
        # possibly by running HandleCreateJob on them, if that's how this gets tied together in HELIO-3879
      else
        title_level_handles["https://hdl.handle.net/2027/#{heb_title_id}"] = Rails.application.routes.url_helpers.hyrax_monograph_url(@noid)
      end
    end

    title_level_handles
  end

  def book_level_handles
    book_level_handles = {}

    @heb_ids.each do |heb_book_id|
      book_level_handles["https://hdl.handle.net/2027/#{heb_book_id}"] = Rails.application.routes.url_helpers.hyrax_monograph_url(@noid)
    end

    book_level_handles
  end

  def handles
    # TODO: step 1 will be to run `find_duplicate_book_ids(heb_ids)` and message (email fulcrum-dev??) if any are found
    book_level_handles.merge(title_level_handles)
  end
end
